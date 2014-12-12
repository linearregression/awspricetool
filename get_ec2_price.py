import re, sys, itertools 
from collections import defaultdict

infile, outfile = sys.argv[1], sys.argv[2]
d = defaultdict(list)

with open(infile, 'r') as inf, open(outfile, 'w') as ouf:
    line_words = (line.rstrip().split(' ') for line in inf)
    for words in line_words:
        if words[3] == 'GET':
           d[int(words[0])].append(words[4])
        if words[3] == 'Host':
           d[int(words[0])-1].append(words[4])
    
    # full urls
    for key, value in d.iteritems():
        fullurl = 'http://'+value[1]+value[0]
        ouf.writelines(fullurl+'\n')

      

