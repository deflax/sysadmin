#!/bin/bash

rdiff-backup --print-statistics --exclude /proc --exclude /mnt --exclude /media --exclude /sys --exclude /dev $@
