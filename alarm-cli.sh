#!/usr/bin/env bash

CONFIG="$XDG_CONFIG_HOME/alarm.conf"
LOCK="/tmp/alarm.lock"

# The program's default precision in seconds.
data="$XDG_DATA_HOME/alarm"
precision="300"

# We most certainly do not want to clash with the daemon, so let's wait
# for the lock on $LOCK.
exec 9>"$LOCK"
flock --exclusive 9

#=============================================================================#
# Very functional functions.                                                  #
#=============================================================================#

print_usage() {
    cat <<HERE
usage: $0 [option]

Calling $0 without any options will print this help message.

OPTIONS:
    -h          Print this help message.
    -l          List all pending events.
    -d DATADIR  Sets the directory where $0 saves it's events to \$DATADIR.
                If \$DATADIR is an empty string, the default directory,
                "$XDG_DATA_HOME/alarm", will be used. All pending events will
                be copied to the new directory, so the old is save to remove.
    -p SECONDS  Sets the timer's precision in seconds. If \$SECONDS is 0, the
                default precision, $PRECISION, will be used.
    -t TIME     The time to add an event. Should be used together with any
                of -a or -f. \$TIME should be readable by "date -d".
    -a CMD      Runs the command \$CMD at the time supplied by the -t option.
    -f FILE     Runs the script \$FILE at the time supplied by the -t option.
    -n NAME     Used together with the -a and -f options. Names the new event,
                which is shown with -l.
HERE
}

list_events() {
    data=$1 # Data data directory.
    if [ ! -d "$data" ] || [ -z "$(ls -A "$data")" ]; then
        echo "No future events."
    else
        { for file in $(ls "$data/" | sort -n); do
            date="${file%%.*}"  # Before the dot is the date.
            name="${file#*.}"   # After the dot is the name.
            # As the date is only readable with spaces, replace them.
            date="${date//_/ }"
            # Now print them.
            echo "$date - $name"
        done } | cat -n # And number them, for reference later.
    fi
}

move_data() {
    old="$1"
    new="$2"
    mkdir -p "$new"
    if [ -d "$old" ]; then
        cp "$old/*" "$new"
    fi
}

# Filters spaces from the file name.
filter_name() {
    echo "${1// /_}"
}

#=============================================================================#
# Parameter initialization.                                                   #
#=============================================================================#

# Reading the configurations from the config file, if it exists.
if [ -e "$CONFIG" ]; then
    . "$CONFIG"
fi

newdate=
newcmd=
newfile=
newname=
no_options=1

#=============================================================================#
# Parsing the program's options.                                              #
#=============================================================================#

while getopts "hld:p:t:a:f:n:" option; do
    no_options=0
    case $option in
        h)
            print_usage
            exit
            ;;
        l)
            list_events "$data"
            exit
            ;;
        d)
            newdata="$OPTARG"
            if [ -z "$newdata" ]; then
                newdata="$DATA"
            fi
            move_data "$data" "$newdata"
            ;;
        p)
            if [ "$OPTARG" != "0" ]; then
                precision="$OPTARG"
            fi
            ;;
        t)
            newdate="$(date -d "$OPTARG")"
            if [ $? != "0" ]; then
                echo 'Please supply a time readable by `date -d`.' >2
                exit 1
            fi
            ;;
        a)
            newcmd="$OPTARG"
            ;;
        f)
            newfile="$OPTARG"
            ;;
        n)
            newname=$(filter_name "$OPTARG")
            ;;
    esac
done

#=============================================================================#
# Checking the unprocessed options.                                           #
#=============================================================================#

if [ "$newdate" ]; then
    # We'll be inserting the new event at the time $newdate.
    # First, make sure the datadir exists.
    mkdir -p "$data"
    # Now, let's make a new file from the command or given file:
    newevent="$data/${newdate// /_}.$newname"
    if [ "$newcmd" ]; then
        echo "$newcmd" > "$newevent"
    elif [ "$newfile" ]; then
        cat "$newfile" > "$newevent"
    else
        echo "Along with the -t option, -c or -f should be present." 1>&2
        exit 1
    fi
elif [ "$no_options" = "1" ]; then
    print_usage
    exit
fi

#=============================================================================#
# Saving configuration.                                                       #
#=============================================================================#

# Now that the program's run succesful, overwrite the configuration file with
# all new (and old) variables.
cat <<HERE > "$CONFIG"
# This is the configuration file of $0. Though you may edit it freely, I advise
# you to use the scripts options. Then you're sure you won't break anything.
data="$data"
precision="$precision"
HERE
