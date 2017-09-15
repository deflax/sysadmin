#!/bin/bash

cat /proc/acpi/ibm/fan | grep ^speed | cut -d ':' -f 2 | sed -e 's/[[:space:]]*//'
