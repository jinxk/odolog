# Principles

OdoLog is a fuel log. You add your vehicles, you log every refuel, and the app tells you what your mileage and running costs actually are. These are the rules I hold the app to.

## Your data stays on your phone

There is no account and no login. There is no cloud sync, no server, nothing that phones home. Every litre, price, and odometer reading you enter lives in a local SQLite database on the device and nowhere else.

There is no analytics and no telemetry either. If you uninstall the app, the data goes with it, so export your data and back up your database.

## It works offline, at the pump

The app works with the network switched off. Nothing you do day to day waits on a request. Offline is the normal mode, not a fallback, and online-only features do not belong here.

## Accuracy over features

The one thing this app cannot get wrong is the math.

Mileage is only computed between full-tank fills. A partial fill does not close a mileage window; the app waits until the next full tank and computes the distance and fuel across the whole interval. Partial fills are still logged, they just do not produce a mileage number on their own.

Every derived value (mileage in km/l, cost per km, range per tank, monthly spend) follows the same rule. Where a number is not trustworthy, the app says so instead of showing a confident guess.

## Simple by default

Logging a refuel takes under fifteen seconds: litres, amount paid, odometer, save. The fuel variant (XP95, Shell V-Power, ordinary petrol or diesel) is optional and remembered per vehicle, so most of the time you leave it alone.

Everything past that first screen is progressive. Summaries, charts, and per-tank breakdowns are there when you go looking, but they never get in the way of the one thing you opened the app to do. A feature that makes the log-a-refuel path slower needs a very good reason to exist.

## Free forever, MIT

OdoLog is free and MIT licensed. No ads, no paid tier, no "pro" version with the useful features behind a wall. You can read the source, build it yourself, fork it, or ship your own version. The license is not going to change on you later.

## Scope

OdoLog records what a vehicle costs to run and to keep road legal: fuel, mileage, service, non-fuel expenses, and document expiry dates (insurance, PUC, RC, fitness). It does not track routes, GPS, parking, or traffic, and it never sends data anywhere. Requests that move it toward a general vehicle manager will usually be declined.
