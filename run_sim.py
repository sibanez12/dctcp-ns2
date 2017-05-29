#!/usr/bin/env python

"""
Controls the NS-2 simulation runs
"""

import os, sys
import numpy as np
import argparse
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

sys.path.append(os.path.expandvars('$DCTCP_NS2/bin/'))
import ns_tools

PLOTS_DIR = 'plots/'

def make_fig_1():
    for congestion_alg in ['TCP','DCTCP']:
        out_q_file = congestion_alg + '_q_size.out' 
        # run NS-2 simulation
        num_flows = 2
        os.system('ns tcl/run_sim.tcl {0} {1} {2}'.format(congestion_alg, out_q_file, num_flows))
        # parse and plot queue size
        time, q_size = ns_tools.parse_qfile(os.path.join('tcl/out/', out_q_file), t_min=4.0, t_max=9.0)
        plt.plot(time, q_size, linestyle='-', marker='o', label=congestion_alg)

    ns_tools.config_plot('time (sec)', 'queue size (packets)', 'Queue Size over Time')
    ns_tools.save_plot('q_size_vs_time', PLOTS_DIR)


def make_fig_13():
    for num_flows in [2, 20]:
        for congestion_alg in ['TCP','DCTCP']:
            out_q_file = congestion_alg + '_q_size.out' 
            # run NS-2 simulation
            os.system('ns tcl/run_sim.tcl {0} {1} {2}'.format(congestion_alg, out_q_file, num_flows))
            # parse and plot queue size
            time, q_size = ns_tools.parse_qfile(os.path.join('tcl/out/', out_q_file), t_min=4.0, t_max=9.0)
            plt_label = congestion_alg + '_' + str(num_flows) + '_flows'
            # Compute the CDF
            sorted_data = np.sort(q_size)
            yvals=np.arange(len(sorted_data))/float(len(sorted_data)-1)
            plt.plot(sorted_data, yvals, linestyle='-', label=plt_label)

    ns_tools.config_plot('queue size (packets)', 'Cumulative Fraction', 'Queue Length CDF', legend_loc='upper center')
    ns_tools.save_plot('cdf', PLOTS_DIR) 

def make_fig_14():
    pass

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--fig_1', action='store_true')
    parser.add_argument('--fig_13', action='store_true')
    parser.add_argument('--fig_14', action='store_true')
    args = parser.parse_args()

    if (args.fig_1):
        make_fig_1()

    if (args.fig_13):
        make_fig_13()

#    if (args.fig_14):
#        make_fig_14()


if __name__ == "__main__":
    main()

