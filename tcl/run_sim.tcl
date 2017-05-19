
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
set tcp_window 400
# run_time (sec)
set run_time 10.0


#### DCTCP Parameters ####
# DCTCP_K (pkts)
set DCTCP_K 20
# DCTCP_g (0 < g < 1)
set DCTCP_g 0.0625


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

Queue/RED set setbit_ true
Queue/RED set gentle_ false
Queue/RED set q_weight_ 1.0
Queue/RED set mark_p_ 1.0
Queue/RED set thresh_ $DCTCP_K
Queue/RED set maxthresh_ $DCTCP_K


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
if {[string compare $congestion_alg "DCTCP"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g;
}

set tcp1 [$ns create-connection TCP/Reno $h1 TCPSink $h3 1]
$tcp1 set window_ $tcp_window 
set tcp2 [$ns create-connection TCP/Reno $h2 TCPSink $h3 2]
$tcp2 set window_ $tcp_window 
set ftp1 [$tcp1 attach-source FTP]
set ftp2 [$tcp2 attach-source FTP]

# queue monitoring
set qf_size [open $tcl_dir/out/$out_q_file w]
set qmon_size [$ns monitor-queue $s1 $h3 $qf_size $samp_int]
[$ns link $s1 $h3] queue-sample-timeout

#Schedule events for the CBR and FTP agents
$ns at 0.1 "$ftp1 start"
$ns at 0.1 "$ftp2 start"
$ns at [expr $run_time - 0.5] "$ftp2 stop"
$ns at [expr $run_time - 0.5] "$ftp1 stop"

#Call the finish procedure after 5 seconds of simulation time
$ns at $run_time "finish"

#Define a 'finish' procedure
proc finish {} {
    global ns nf qf_size
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

