# Roadmap

Where OdoLog is and where it is going. The short version lives in the README.

## Shipped

- **0.1**: vehicles, the refuel log, and the core stats (mileage, cost per km, range per tank, monthly spend).
- **1.0**: visual overhaul, mileage trend, CSV backup and restore, claimed mileage comparison, document expiry reminders, service log with due reminders, non-fuel expenses.
- **1.1**: history tab folding in the service log and expenses, JSON backup format, automatic daily backups that survive an uninstall, restore from the welcome screen, rupee first entry with amount chips, screen reader labels.
- **1.2**: import runs as one transaction and refuses rows that name a vehicle it cannot find, error states with a retry, the vehicle switcher on every tab, a shorter start-up sweep.
- **1.3**: manual odometer updates, undo after a delete, delete all data from Settings, a warning for fills past the tank capacity, a reminders section in Settings, and the notification prompt only when there is something to remind about.
- **1.4**: project polish. Changelog, privacy page, this file, issue and pull request templates, a security policy, minified release builds, and an APK attached to the release with its SHA-256.

## Next

- A Play Store release, after a closed test.
- An F-Droid listing.
- Notification behaviour checked on more phones, including the OEM battery savers that like to kill scheduled work.

## Maybe later

- Hindi, and the localisation scaffolding that has to come first.
- Fuel presets for countries other than India. This is a good first pull request.
- An iOS release, once there is a device to test it on properly.

## Not planned

Each of these has been asked for or considered and turned down. One line each on why.

- A gig rider earnings ledger. It turns a fuel log into an income app.
- Electric vehicles. A second math engine to keep correct.
- Bi-fuel CNG plus petrol on one vehicle. It puts the one number that cannot be wrong at risk.
- A home screen widget. For a number that changes twice a month.
- A price per litre trend. It rates something you cannot act on.
- Snoozing a reminder. The reminder ladder already re-fires at 30, 15, 7 and 1 days.
- Per trip tags. Nobody logs a fuel entry per trip.
- Demo data on first run. It creates a "how do I remove the demo" problem.
- A monthly budget. It adds a target setting surface to an app that is simple by default.
- Routes, GPS, parking, and traffic. See [principles.md](principles.md).
