#!/bin/bash

# usage ./ffmpegrecord.sh http://audiostream.tld:8000 mp3
#       ./ffmpegrecord.sh https://videostream/hls/hmsu.m3u8 mkv

while true; do
    today=`date +%Y-%m-%d-%H%M%S`
    ffmpeg -re -i $1 -c copy rec-$today.$2
    sleep 1
done;
