# Privacy

OdoLog collects nothing.

There is no account and no login. There is no analytics, no telemetry, and no crash reporter. The app declares no internet permission, so it cannot make a network call even by mistake.

## Where your data lives

Everything you enter, vehicles, refuels, service entries, expenses, odometer readings and document dates, is written to a SQLite database inside the app's own storage on your phone. Nothing else can read it.

Two copies can exist outside that database, and you control both:

- A backup file you export yourself, saved wherever you choose to put it.
- The automatic daily backup, if you turned it on, written to Downloads/OdoLog and kept to the last seven days. Files there survive an uninstall.

Android's own automatic backup may also keep a copy of the app's data in your Google account, the same way it does for other apps on the phone. Turn it off in Android's settings, under Backup, if you would rather it did not.

## Deleting everything

Settings, Data, Delete all data clears every table and cancels every scheduled reminder. Files you exported and the automatic backups in Downloads/OdoLog are yours and are not touched, so delete those separately if you want them gone.

Uninstalling the app removes the database with it, and also leaves the files in Downloads/OdoLog behind.

## Permissions

- Notifications, so document expiry and service due reminders can arrive. Asked for the first time you save an expiry date or log a service, not at first launch.
- Receive boot completed, so reminders set before a restart are rescheduled after it.
- Vibrate, which the notification library declares so a reminder can buzz the phone.

That is the whole list.
