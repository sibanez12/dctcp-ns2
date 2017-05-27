#!/usr/bin/env python

"""
Controls the NS-2 simulation runs
"""

import os, sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

sys.path.append(os.path.expandvars('$DCTCP_NS2/bin/'))
import plot_queue

PLOTS_DIR = 'plots/'

def run_sim():

    for congestion_alg in ['TCP','DCTCP']:
        out_q_file = congestion_alg + '_q_size.out' 
        # run NS-2 simulation
        os.system('ns tcl/run_sim.tcl {0} {1}'.format(congestion_alg, out_q_file))
        # parse and plot queue size
        time, q_size = plot_queue.parse_qfile(os.path.join('tcl/out/', out_q_file))
        plt.plot(time, q_size, linestyle='-', marker='o', label=congestion_alg)

    plot_queue.config_plot('time (sec)', 'queue size (packets)', 'Queue Size over Time', [4.0, 9.0])
    plot_queue.save_plot('q_size_vs_time', PLOTS_DIR)


def main():
    run_sim()


if __name__ == "__main__":
    main()

