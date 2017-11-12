#!/bin/bash

ffmpeg -f x11grab -s 1366x768 -r 15 -i :0.0 -f alsa -i pulse -vcodec libx264 -preset ultrafast -crf 0 -acodec libmp3lame -ac 2 -ab 256k -ar 44100 -f flv "rtmp://localhost:1935/live"
