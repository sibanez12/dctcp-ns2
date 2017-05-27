
#
# Create a simple 3 host topology:
#
#         h1    
#          \    
# 100Mb,1ms \  100Mb, 1ms 
#           s1 ---------- h3 
# 100Mb,1ms /   
#          /    
#         h2    
#

if {$argc != 2} {
    puts "wrong number of arguments, expected 2, got $argc"
    exit 0
}

set congestion_alg [lindex $argv 0]
set out_q_file [lindex $argv 1]

# samp_int (sec)
set samp_int 0.01
# q_size (pkts)
set q_size 200
# link_cap (Mbps)
set link_cap 100Mbps
# link_delay (ms)
set link_delay 0.25ms
# tcp_window (pkts)
set tcp_window 1000000
# run_time (sec)
set run_time 10.0
# pktSize (bytes)
set pktSize 1460

#### DCTCP Parameters ####
# DCTCP_K (pkts)
set DCTCP_K 20
# DCTCP_g (0 < g < 1)
set DCTCP_g 0.0625
# ackRatio
set ackRatio 1

##### Switch Parameters ####
set drop_prio_ false
set deque_prio_ false

set tcl_dir $::env(TCL_DIR)

#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red

#Open the NAM trace file
set nf [open $tcl_dir/out/out.nam w]
$ns namtrace-all $nf

#Create four nodes
set h1 [$ns node]
set h2 [$ns node]
set s1 [$ns node]
set h3 [$ns node]

# Queue options
Queue set limit_ $q_size

Queue/DropTail set mean_pktsize_ [expr $pktSize+40]
Queue/DropTail set drop_prio_ $drop_prio_
Queue/DropTail set deque_prio_ $deque_prio_

#Queue/RED set bytes_ false
#Queue/RED set queue_in_bytes_ true
Queue/RED set mean_pktsize_ $pktSize
Queue/RED set setbit_ true
Queue/RED set gentle_ false
Queue/RED set q_weight_ 1.0
Queue/RED set mark_p_ 1.0
Queue/RED set thresh_ $DCTCP_K
Queue/RED set maxthresh_ $DCTCP_K
Queue/RED set drop_prio_ $drop_prio_
Queue/RED set deque_prio_ $deque_prio_


#Create links between the nodes
if {[string compare $congestion_alg "DCTCP"] == 0} { 
    $ns duplex-link $h1 $s1 $link_cap $link_delay RED 
    $ns duplex-link $h2 $s1 $link_cap $link_delay RED 
    $ns duplex-link $s1 $h3 $link_cap $link_delay RED 
} else {
    $ns duplex-link $h1 $s1 $link_cap $link_delay DropTail
    $ns duplex-link $h2 $s1 $link_cap $link_delay DropTail
    $ns duplex-link $s1 $h3 $link_cap $link_delay DropTail
}

#Give node position (for NAM)
$ns duplex-link-op $h1 $s1 orient right-down
$ns duplex-link-op $h2 $s1 orient right-up
$ns duplex-link-op $s1 $h3 orient right

#Monitor the queue for link (s1-h3). (for NAM)
$ns duplex-link-op $s1 $h3 queuePos 0.5

# HOST options
Agent/TCP set window_ $tcp_window
Agent/TCP set windowInit_ 2
Agent/TCP set packetSize_ $pktSize
Agent/TCP/FullTcp set segsize_ $pktSize

if {[string compare $congestion_alg "DCTCP"] == 0} {
    Agent/TCP set ecn_ 1
    Agent/TCP set old_ecn_ 1
    Agent/TCP/FullTcp set spa_thresh_ 0
    Agent/TCP set slow_start_restart_ true
    Agent/TCP set windowOption_ 0
    Agent/TCP set tcpTick_ 0.000001
#    Agent/TCP set minrto_ $min_rto
#    Agent/TCP set maxrto_ 2
    
    Agent/TCP/FullTcp set nodelay_ true; # disable Nagle
    Agent/TCP/FullTcp set segsperack_ $ackRatio;
    Agent/TCP/FullTcp set interval_ 0.000006

    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g;

    # setup flow 1
    set tcp1 [new Agent/TCP/FullTcp]
    set sink1 [new Agent/TCP/FullTcp]
    $ns attach-agent $h1 $tcp1
    $ns attach-agent $h3 $sink1
    $tcp1 set fid_ 1
    $sink1 set fid_ 1
    $ns connect $tcp1 $sink1
    # set up TCP-level connections
    $sink1 listen

    # setup flow 2
    set tcp2 [new Agent/TCP/FullTcp]
    set sink2 [new Agent/TCP/FullTcp]
    $ns attach-agent $h2 $tcp2
    $ns attach-agent $h3 $sink2
    $tcp1 set fid_ 2
    $sink1 set fid_ 2
    $ns connect $tcp2 $sink2
    # set up TCP-level connections
    $sink2 listen

} else {

    set tcp1 [$ns create-connection TCP/Reno $h1 TCPSink $h3 1]
    set tcp2 [$ns create-connection TCP/Reno $h2 TCPSink $h3 2]
}

set ftp1 [$tcp1 attach-source FTP]
$ftp1 set type_ FTP
set ftp2 [$tcp2 attach-source FTP]
$ftp2 set type_ FTP

# queue monitoring
set qf_size [open $tcl_dir/out/$out_q_file w]
set qmon_size [$ns monitor-queue $s1 $h3 $qf_size $samp_int]
[$ns link $s1 $h3] queue-sample-timeout

#Schedule events for the CBR and FTP agents
$ns at 0.1 "$ftp1 start"
$ns at 1.5 "$ftp2 start"
$ns at [expr $run_time - 0.5] "$ftp2 stop"
$ns at [expr $run_time - 0.5] "$ftp1 stop"

#Call the finish procedure after 5 seconds of simulation time
$ns at $run_time "finish"

#Define a 'finish' procedure
proc finish {} {
    global ns nf qf_size tcl_dir
    $ns flush-trace
    #Close the NAM trace file
    close $nf
    close $qf_size
    #Execute NAM on the trace file
#    exec nam $tcl_dir/out/out.nam &
    exit 0
}

#Run the simulation
$ns run

