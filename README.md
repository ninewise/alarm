
Alarm
=====

An alarm daemon I wrote for myself.

Running the daemon in the background, you can use the cli to add "events" to
the queue, which will be invoked when the time is right. These events are just
bash scripts or commands.

You can use this daemon to remind you of things on short notice (like that you
really should go sleeping), or long time planning (sending you a mail the day
before your exam).

## Known bugs

As the daemon and the cli use the same files, they might clash. For now, try
to run the cli while the daemon is sleeping.

## Possible features

I've already implemented listing future events with a `-l` option. This list
also shows id's, so I might implement removing future events.

Maybe I'll write some default scripts, too. Like mail, or notifications.
