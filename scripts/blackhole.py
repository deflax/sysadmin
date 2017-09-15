#!/usr/bin/python3

# simple ip blackhole list :)
# afx Nov 2016
#
# requires Pygtail
# should be installed to iptables filtered machine with DROP and LOG policy
# the idea is that any traffic coming to this serviceless machine can be assumed 
# as bad and then listed for further processing

from pygtail import Pygtail

import sys
import signal
import re
import time
import json

kernlog = '/var/log/kern.log'
dbfile = '/var/www/html/blacklist.txt'

#add whitelisted ips here:
whitelist = [ '1.2.3.4',
              '5.6.7.8' ]

######

def signal_handler(signal, frame):
    print('You\'ve pressed Ctrl+C. Listing stats and exiting...')
    print('')
    print(json.dumps(stats))
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

print('.o.oOo.o. blackhole.py by afx .o.oOo.o.')
print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
print('Whitelist: {}'.format(whitelist))
blacklist = []
stats = {}
try:
    blackfile = open(dbfile, 'r')
    for item in blackfile:
        blacklist.append(item.strip())
    blackfile.close()
    print('Blacklist: {}'.format(blacklist))
except Exception as e:
    print(e)
    print('Blacklist empty.')
print('')

while True:
    time.sleep(1)
    for line in Pygtail(kernlog):
        query = re.findall( r'SRC=[0-9]+(?:\.[0-9]+){3}', line )
        newip = query[0][4:]
        if newip in whitelist:
            print('{} whitelisted'.format(newip))
            continue
        elif newip in blacklist:
            try:
                oldcounter = stats[newip]
            except:
                oldcounter = 0
            counter = oldcounter + 1
            stats.update({ newip: counter })
            print('{} -> {}'.format(newip, str(stats[newip])))
        else:
            print('{} blackholed'.format(newip))
            blacklist.append(newip)
            blackfile = open(dbfile, 'w')
            for item in blacklist:
                blackfile.write("%s\n" % item)
            blackfile.close()
            
#EOF
