#!/bin/bash

cat /sys/devices/virtual/thermal/thermal_zone0/hwmon1/temp1_input | head -c2
