#!/bin/bash

export LC_TIME="en_US.UTF-8"
TIME=$(date +"%H:%M")
DATE=$(date +"%a %d/%m")

BATTERY_CHECK_CMD=$(pmset -g batt)
BATTERY_PERCENTAGE=$(echo "$BATTERY_CHECK_CMD" | egrep '([0-9]+\%).*' -o --colour=auto | cut -f1 -d'%')
BATTERY_STATUS=$(echo "$BATTERY_CHECK_CMD" | grep "'.*'" | sed "s/'//g" | cut -c 18-19)
BATTERY_REMAINING=$(echo "$BATTERY_CHECK_CMD" |  egrep -o '([0-9]+%).*' | cut -d\  -f3)

BATTERY_CHARGING=""
if [ "$BATTERY_STATUS" == "Ba" ]; then
  BATTERY_CHARGING="false"
elif [ "$BATTERY_STATUS" == "AC" ]; then
  BATTERY_CHARGING="true"
fi

LOAD_AVERAGE=$(sysctl -n vm.loadavg | awk '{print $2}')

WIFI_STATUS=$(ifconfig en0 | grep status | cut -c 10-)
WIFI_SSID=$(networksetup -getairportnetwork en0 | cut -c 24-)

DND=$(defaults -currentHost read com.apple.notificationcenterui doNotDisturb)

MEM_CHECK_CMD=$(memory_pressure)

MEM_INACTIVE=$(echo "$MEM_CHECK_CMD" | grep "Pages inactive" | grep -o -E '[0-9]+')
MEM_FREE=$(echo "$MEM_CHECK_CMD" | grep "Pages free" | grep -o -E '[0-9]+' | awk -v MEM_INACTIVE=$MEM_INACTIVE '{ print $1 + MEM_INACTIVE }')
MEM_TOTAL=$(echo "$MEM_CHECK_CMD" | grep system | awk -F" " '{print $5}' | grep -o -E '[0-9]+')

MEM_USED=$(echo | awk -v MEM_TOTAL=$MEM_TOTAL -v MEM_FREE=$MEM_FREE '{ print MEM_TOTAL - MEM_FREE }')
MEM_USED_PERCENT=$(echo | awk -v MEM_USED=$MEM_USED -v MEM_TOTAL=$MEM_TOTAL '{ print (MEM_USED / MEM_TOTAL) * 100}')


echo $(cat <<-EOF
{
    "memory": {
        "used": "$MEM_USED_PERCENT"
    },
    "datetime": {
        "time": "$TIME",
        "date": "$DATE"
    },
    "battery": {
        "percentage": $BATTERY_PERCENTAGE,
        "charging": $BATTERY_CHARGING,
        "remaining": "$BATTERY_REMAINING"
    },
    "cpu": {
        "loadAverage": $LOAD_AVERAGE
    },
    "wifi": {
        "status": "$WIFI_STATUS",
        "ssid": "$WIFI_SSID"
    },
    "dnd": $DND
}
EOF
)
