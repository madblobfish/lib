#!/usr/bin/env python3

# some thing i adopted from somewhere and edited a little
# it generates a heatmap of git commits with gnuplot

import argparse
import datetime
import subprocess
import os
import sys
import math

parser = argparse.ArgumentParser(description="Create heatmaps of git commits")
parser.add_argument("--author",  help="Author whose git commits are to be counted", type=str)
parser.add_argument("--name",  help="name of the file", type=str)
parser.add_argument("--log",  help="logarithmic scale", action="store_true")
parser.add_argument("--format",  help="output format", type=str)
parser.add_argument("directory", help="git directory to use", metavar="DIR")

arguments = parser.parse_args()

directory = os.path.join(arguments.directory, ".git")
author = arguments.author or ""
log = arguments.log or False
forma = arguments.format or "png"
name = arguments.name or directory.replace("/","_").replace("_.git","")

commits = subprocess.check_output([
  "git",
  "--git-dir=%s" % directory,
  "log",
  "--pretty=format:%ct",
  "--author=%s" % author
])
counts = [ [0]*24 for _ in range(7) ]

for commit in commits.decode().split():
    d   = datetime.datetime.fromtimestamp(int(commit))
    row = d.weekday()
    col = d.hour

    counts[row][col] += 1

cmd =['set terminal '+forma+'\n'
      'load \'YlOrRd.plt\'\n'
      'set output \''+name+'.'+forma+'\'\n'
      'set size ratio 7.0/24.0\n'
      'set xrange [-0.5:23.5]\n'
      'set yrange [-0.5: 6.5]\n'
      'set xtics 0,1\n'
      'set ytics 0,1\n'
      'set xtics offset -0.5,0.0\n'
      'set tics scale 0,0.001\n'
      'set mxtics 2\n'
      'set mytics 2\n'
      'set grid front mxtics mytics linetype -1 linecolor rgb \'black\'\n'
      'plot \'-\' matrix with image notitle\n']
for row in range(7):
    for col in range(24):
        if log:
          cmd.append(str(math.log(counts[row][col] + 1)) + " ")
        else:
          cmd.append(str(counts[row][col]) + " ")
    cmd.append("\n")
cmd.append("e")

def execute():
    writeplt()

    f = open(name+'.dat', 'w')
    f.write("".join(str(x) for x in cmd))
    f.close()

    f = open(name+'.dat', 'r')
    gnuplot = subprocess.Popen(["gnuplot"], stdin=f)
    gnuplot.wait()
    f.close()
    os.remove(name+'.dat')
    os.remove('YlOrRd.plt')
    return

def writeplt():
    f = open("YlOrRd.plt", "w")
    f.write("# line styles for ColorBrewer YlOrRd\n# for use with sequential data\n# provides 8 yellow-orange-red colors of increasing saturation\n# compatible with gnuplot >=4.2\n# author: Anna Schneider\n\n# line styles\nset style line 1 lc rgb '#FFFFCC' # very light yellow-orange-red\nset style line 2 lc rgb '#FFEDA0' #\nset style line 3 lc rgb '#FED976' # light yellow-orange-red\nset style line 4 lc rgb '#FEB24C' #\nset style line 5 lc rgb '#FD8D3C' #\nset style line 6 lc rgb '#FC4E2A' # medium yellow-orange-red\nset style line 7 lc rgb '#E31A1C' #\nset style line 8 lc rgb '#B10026' # dark yellow-orange-red\n\n# palette\nset palette defined (\\\n 0 '#FFFFCC',\\\n 1 '#FFEDA0',\\\n 2 '#FED976',\\\n 3 '#FEB24C',\\\n 4 '#FD8D3C',\\\n 5 '#FC4E2A',\\\n 6 '#E31A1C',\\\n 7 '#B10026' )")
    f.close()
    return

execute()
