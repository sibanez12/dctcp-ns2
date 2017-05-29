#!/usr/bin/env python


"""
Parse the sampled queue size output file and plot the queue size over time
"""

import sys, os, re, argparse
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages


def parse_qfile(fname, t_min=None, t_max=None):
    fmat = r"(?P<time>[\d.]*) (?P<from_node>[\d]*) (?P<to_node>[\d]*) (?P<q_size_B>[\d.]*) (?P<q_size_p>[\d.]*) (?P<arr_p>[\d.]*) (?P<dep_p>[\d.]*) (?P<drop_p>[\d.]*) (?P<arr_B>[\d.]*) (?P<dep_B>[\d.]*) (?P<drop_B>[\d.]*)"

    time = []
    q_size = []
    with open(fname) as f:
        for line in f:
            searchObj = re.search(fmat, line)
            if searchObj is not None:
                t = float(searchObj.groupdict()['time'])
                if (t_min is not None and t < t_min):
                    continue
                if (t_max is not None and t > t_max):
                    continue
                time.append(t)
                s = float(searchObj.groupdict()['q_size_p'])
                q_size.append(s)
    
    return time, q_size

def config_plot(xlabel, ylabel, title, legend_loc=None):
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    plt.title(title)
    plt.grid()
    plt.legend(loc=legend_loc)

def save_plot(filename, out_dir):    
    plot_filename = os.path.join(out_dir, filename + '.pdf')
    pp = PdfPages(plot_filename)
    pp.savefig()
    pp.close()
    print "Saved plot: ", plot_filename

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--qmon_file", type=str, required=True,
		help="The queue monitor output file")
    parser.add_argument("--out_dir", type=str, default="",
		help="The directory to write output files into")

    try:
        args = parser.parse_args()
    except:
        print >> sys.stderr, "ERROR: failed to parse command line options"
        sys.exit(1)

    # create output directory if it doesn't exist
    if not os.path.exists(args.out_dir):
        os.makedirs(args.out_dir)

    # parse and plot queue size
    time, q_size = parse_qfile(args.qmon_file)
    plt.plot(time, q_size, linestyle='-', marker='o')
    config_plot('time (sec)', 'queue size (packets)', 'Queue Size over Time')
    save_plot('q_size_vs_time', args.out_dir)


if __name__ == "__main__":
    main()

