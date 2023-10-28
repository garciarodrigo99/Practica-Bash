#!/bin/bash

pids=()
while IFS= read -r linea; do
    pids+=("$linea")
done < <(ps -u"${USER}" --no-headers | tr -s ' ' | cut -d ' ' -f2)

#echo "${pids[*]}"

for pid in "${pids[@]}"; do
    if [ -d "/proc/$pid" ]; then
        #pid_info=$(cat "/proc/$pid/status")
        # Realizar otras operaciones con pid_info si es necesario
        cat /proc/$pid/status | grep 'TracerPid'
    fi
    #$pid_info $(| grep TracerPid)
done