# Principles

OdoLog is a fuel log. You add your vehicles, you log every refuel, and the app tells you what your mileage and running costs actually are. That is the whole thing. These are the ideas I hold the app to, and the reasons behind them.

## Your data stays on your phone

There is no account and no login. There is no cloud sync, no server, nothing that phones home. Every litre, price, and odometer reading you enter lives in a local SQLite database on the device and nowhere else.

That means no analytics and no telemetry either. I do not know how many vehicles you have or how often you fill up, and I would like to keep it that way. If you uninstall the app, the data goes with it, so an export feature matters more here than in an app that keeps a copy on some server. Back up your database.

## It works offline, at the pump

You log a refuel standing next to a fuel dispenser, often with one bar of signal or none. So the app has to work with the network switched off entirely. Nothing you do day to day should ever wait on a request.

Offline is not a fallback mode. It is the normal mode. Online-only features do not belong here.

## Accuracy over features

The single job this app cannot get wrong is the math. If the mileage number is off, the app is worse than useless, because you will trust a wrong number.

The rule that matters most: mileage is only computed between full-tank fills. If you top up half a tank, the app does not know how much fuel you actually burned since the last reading, so it will not invent a figure. It waits until the next full tank and computes the distance and fuel across the whole interval. Partial fills still get logged, they just do not produce a mileage number on their own. This is the standard way to measure real consumption, and it is worth the small explanation every user needs once.

Every derived value (mileage in km/l, cost per km, range per tank, monthly spend) follows from the same discipline. When I am unsure whether a number is trustworthy, the app should say so rather than show a confident guess.

## Simple by default

Logging a refuel should take under fifteen seconds: litres, amount paid, odometer, save. The fuel variant (XP95, Shell V-Power, ordinary petrol or diesel) is optional and remembered per vehicle, so most of the time you leave it alone.

Everything past that first screen is progressive. Summaries, charts, and per-tank breakdowns are there when you go looking, but they never get in the way of the one thing you opened the app to do. If a feature makes the log-a-refuel path slower, it needs a very good reason to exist.

## Free forever, MIT

OdoLog is free and MIT licensed. No ads, no paid tier, no "pro" version dangling the useful features behind a wall. You can read the source, build it yourself, fork it, or ship your own version. The license is not going to change on you later.

## Honest scope

This started as a fuel log and it has widened, on purpose but slowly, into a record of what a vehicle costs to run and keep road legal. Document expiry reminders (insurance, PUC, RC, fitness), a service log with due reminders, and expense tracking for the non-fuel costs (tyres, repairs, insurance premiums) are all in, because a lapsed paper is a real fine and a tyre change is a real cost, and both sit right next to the running costs the app already tracks. What stays out is the rest of the car super-app: your driving route, GPS, parking spots, live traffic, and anything that phones home. Those are real needs and other apps handle them.

I would rather ship a small app that gets fuel and mileage exactly right than a big one that does ten things at seventy percent. When someone asks for a feature that pulls the app toward being a general vehicle manager, the honest answer is usually no, and that no is a feature in itself.
