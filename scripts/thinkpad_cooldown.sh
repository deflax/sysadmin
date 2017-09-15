#!/bin/bash

# install:

# echo "options thinkpad_acpi fan_control=1" >> /etc/modprobe.d/thinkpad_acpi.conf

echo "-- ] thinkpad cooldown swtich [ --"
echo ""
echo ""

while true; do
  echo level disengaged > /proc/acpi/ibm/fan
  echo
  echo "> max speed"
  echo "Press key to return to switch mode..."
  read -n 1

  echo level auto > /proc/acpi/ibm/fan
  echo
  echo "> auto"
  echo "Press key to return to switch mode..."
  read -n 1
done

