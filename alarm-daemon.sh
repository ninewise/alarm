#!/usr/bin/env bash

CONFIG="$XDG_CONFIG_HOME/alarm.conf"

# Defaults, in case the program hasn't been initialized yet.
data="$XDG_DATA_HOME/alarm"
precision=300

# Run in the root folder, in case someone invoked us from a mounted fs.
cd /

# Yay, infinite loop in the background!
{
    while true; do

        . "$CONFIG"

        if [ -d "$data" ]; then
            for file in $(ls "$data"); do
                date="${file%%.*}"
                date="${date//_/ }"
                if [ $(date -d "$date" +"%s") -le $(date +"%s") ]; then
                    bash "$data/$file"
                    rm "$data/$file"
                fi
            done
        fi

        sleep "$precision"

    done
} &
