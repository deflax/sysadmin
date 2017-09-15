#!/bin/bash

cat /sys/devices/virtual/hwmon/hwmon1/temp1_input | head -c2
