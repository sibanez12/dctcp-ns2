#!/bin/bash

source settings.sh
./run_sim.py --fig_1 --fig_13 --fig_14
python -m SimpleHTTPServer
