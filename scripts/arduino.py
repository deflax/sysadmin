#!/usr/bin/env python

""" arduino reader by afx """

import time, serial
from sys import argv

def query_arduino():
    global serial
    serial = serial.Serial('/dev/ttyACM0', 9600)
    serial.write('1')
    query = serial.readline().strip('\r\n').split()
    fo = open('/etc/scripts/.arduino.db', 'wb')
    fo.write(','.join(query))
    fo.close()

def print_arduino(pmode):
    fr = open('/etc/scripts/.arduino.db', 'r+')
    rquery = fr.read(100);
    print(rquery.split(',')[pmode])
    fr.close()

if __name__ == "__main__":
    mode = argv
    if mode[1] == 'temp':
        print_arduino(0)
    elif mode[1] == 'humid':
        print_arduino(1)
    elif mode[1] == 'query':
        query_arduino()
    else:
        print('Usage: script.py [temp] [humid]')

