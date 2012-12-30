#!/usr/bin/env bash

CONFIG="$XDG_CONFIG_HOME/alarm.conf"
LOCK="/tmp/alarm.lock"

# Defaults, in case the program hasn't been initialized yet.
data="$XDG_DATA_HOME/alarm"
precision=300

# Run in the root folder, in case someone invoked us from a mounted fs.
cd /

# Close file descriptors.
exec 0>&-
exec 1>&-
exec 2>&-

# Yay, infinite loop!
while true; do

    {   # Execute under read lock on the config file.
        flock --shared 9 # Wait for lock.

        # Get the configuration data.
        . "$CONFIG"

        # Execute each file that's past date.
        if [ -d "$data" ]; then
            for file in $(ls "$data"); do
                date="${file%%.*}"
                date="${date//_/ }"
                if [ $(date -d "$date" +"%s") -le $(date +"%s") ]; then
                    ( bash "$data/$file" ; rm "$data/$file" ; ) &
                fi
            done
        fi

        sleep 5

    } 9>"$LOCK"

    # And wait for the next run.
    sleep "$precision"

done
