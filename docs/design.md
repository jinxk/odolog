# OdoLog Design

## Overview and goals

OdoLog is a small Android app for logging fuel fills and reading back what your driving actually costs. You add a vehicle, record each refuel (how much you put in, what you paid, and the odometer reading), and the app works out mileage, cost per kilometre, and running totals. Everything stays on the phone.

The design centres on three ideas:

1. Logging a fill should take seconds, not minutes. The three numbers that matter (odometer, quantity, price) sit at the top of the form and everything else is optional.
2. The stats have to be correct, not just plausible. Fuel economy math is easy to get subtly wrong when partial fills are involved, so the calculation rules are spelled out exactly in this document.
3. It works for Indian drivers out of the box (fuel brand presets, litres and kg, rupee prices) without being locked to India.

Concrete goals for the first release:

- Add and manage multiple vehicles of different fuel categories.
- Log a full or partial refuel in under 15 seconds for the common case.
- Show latest mileage, cost per kilometre, last-fill range, and monthly and lifetime aggregates per vehicle.
- Export and import data as CSV, and back up and restore the whole database as JSON, so the user is never trapped.
- Ship with a fuel variant catalog covering the major Indian oil companies, editable without a code change.

## Non-goals

These are deliberately out of scope for v1. They are listed so the scope stays honest.

- **No cloud sync and no accounts.** Data lives in local SQLite. No login, no server.
- **No telemetry.** The app does not phone home. No analytics SDK, no crash reporting that ships data off device.
- **No social or sharing features.** No leaderboards, no friends, no comparing your mileage with strangers.
- **Running costs and paperwork are growing in, carefully.** Document expiry reminders (insurance, PUC, RC, fitness) landed in v0.2, and a basic service log is planned next. Full workshop management (parts, labour, a per-component service history) stays out, and so do driving routes, GPS, and anything that leaves the device.
- **No live fuel price feeds.** Prices are whatever the user typed. The app does not fetch pump rates.
- **No cost splitting, no trip logging, no GPS.** OdoLog records fills, not journeys.

## Personas

The people I am building this for are ordinary Indian vehicle owners who care about running costs: the two-wheeler commuter tracking whether a premium petrol actually improves mileage on their scooter, and the car owner who wants a clear monthly fuel spend and a real cost per kilometre rather than a guess. They are comfortable with a phone but not looking for a spreadsheet. They fill up, they want to punch in three numbers at the pump or just after, and they want honest stats later.

## Screen by screen

### Onboarding and first vehicle

First launch drops straight into "add your first vehicle". No sign-up wall, no tour. The screen asks for a name (for example "Activa" or "Swift"), a vehicle type (car, motorcycle, scooter, other), and a fuel category (petrol, diesel, CNG, LPG). Registration number and tank capacity are optional and sit below a "more details" divider.

Once saved, the app lands on the home dashboard for that vehicle, showing an empty state that invites the first refuel. There is no requirement to enter a starting odometer as a separate step; the first refuel entry carries it.

### Home dashboard

This is the screen the user sees most, so it earns the most care. Top to bottom:

- **Greeting header.** A light rounded bar with a small wordmark, a friendly greeting, and the active vehicle selector. Tapping the vehicle name opens a quick switcher if more than one vehicle exists.
- **Hero stat card.** A rounded card in the ink base with the amber accent (see Theme and palette). It shows the two headline numbers: latest mileage (km/l or km/kg) and cost per kilometre. A small caption notes which fills the mileage came from (for example "over your last full-tank window"). Before there is enough data, this card shows a calm empty state instead of zeros.
- **Quick actions row.** Four small tiles: Add refuel, Vehicles, History, Stats.
- **Card sections below.** Last fill summary (date, quantity, price, price per unit, distance since previous), this month's spend and distance, and a small mileage trend once several full-tank windows exist.

The centre of gravity is the Add refuel action, which is also reachable from the bottom navigation.

### Add refuel

The form is ordered for speed. Three large, keypad-friendly fields first, in the order a person reads them off the pump and dashboard:

1. **Odometer reading** (km)
2. **Quantity filled** (litres, or kg when the vehicle is CNG)
3. **Total price paid** (rupees)

Below those, a collapsed "optional details" section holds: fuel variant (dropdown from the catalog), date and time (defaults to now), full tank toggle (defaults on), station name, and notes. Most fills never expand this section, which is the point.

A running hint under the price field shows the derived price per unit as the user types, so a wrong entry is obvious immediately. Save validates (see validation rules) and returns to where the user came from.

### History

A reverse-chronological timeline of fills for the active vehicle. Each row shows date, quantity, price, and, where computable, the per-window mileage and cost per kilometre. Full and partial fills are visually distinct (a partial fill is marked, since it does not close a mileage window on its own). Tapping a row opens the entry detail.

### Entry detail

The full record for one fill: all stored fields plus the derived values that involve this entry (price per unit, distance since previous entry, and, if this fill closed a full-tank window, the mileage and cost per kilometre for that window). Edit and delete live here. Editing an entry recomputes any affected windows, because one changed odometer reading can move two mileage numbers.

### Stats

Per vehicle, this screen collects the aggregates:

- Lifetime: total spend, total distance, total quantity, average mileage, average cost per kilometre.
- This month and previous months: same measures, grouped by calendar month.
- A mileage-over-time chart, one point per closed full-tank window.

Every figure here has a defined empty state. Nothing shows until the second entry exists, and window-based figures wait for the second full-tank fill.

### Vehicle management

List of vehicles with add, edit, and delete. Deleting a vehicle warns that its refuel history goes with it and asks for confirmation. Editing tank capacity later is allowed and only affects projected range, not historical mileage.

### Settings

- **Theme:** system, light, or dark.
- **Units display:** the fuel unit follows the vehicle's category automatically (litres vs kg); currency is rupees by default with a symbol setting for users elsewhere.
- **Export CSV:** writes refuel entries (and a vehicles file) to a location the user picks, for spreadsheets or archiving.
- **Import CSV:** reads entries back, with a preview and a validation pass so a malformed row does not silently corrupt the log.
- **Backup JSON:** a single file containing all vehicles and entries, for full restore.
- **Restore JSON:** replaces or merges from a backup file, with a clear warning before it overwrites.
- **About:** version, licence (MIT), and a link to the source.

## Calculations

This is the core of the app, so the rules are stated exactly. All money is in rupees, distance in kilometres, quantity in litres (or kg for CNG). "Unit" below means litre or kg depending on the vehicle's fuel category.

### Per-entry values

**Price per unit** for an entry:

```
price_per_unit = price_paid / quantity
```

**Distance since previous entry** (needs a previous entry to exist):

```
distance_since_previous = odometer(this) - odometer(previous)
```

### Mileage over full-tank windows

Mileage is only meaningful between two full-tank fills, because only then do you know the tank started full and ended full, so the fuel you added equals the fuel you burned over that distance.

A **full-tank window** is the span from one full-tank fill (the opening fill) to the next full-tank fill (the closing fill). Partial fills may sit inside the window. The opening fill's own fuel belongs to the *previous* window, not this one, because it was burned before this window started.

For a window that opens at full fill `A` and closes at the next full fill `B`:

```
fuel_consumed = sum of quantity for every fill AFTER A, up to and INCLUDING B
distance      = odometer(B) - odometer(A)
mileage       = distance / fuel_consumed          (km/l, or km/kg for CNG)
cost_in_window = sum of price_paid for every fill AFTER A, up to and including B
cost_per_km   = cost_in_window / distance
```

A partial fill inside the window contributes its quantity and price to the window totals but does not produce a mileage point of its own. You cannot compute mileage at a partial fill, because you do not know how full the tank was.

The **latest mileage** shown on the dashboard is the mileage of the most recently closed full-tank window.

### Range

**Range of last fill** is simply the distance driven between the last two entries:

```
last_fill_range = odometer(latest) - odometer(previous)
```

**Projected range** is available only when the vehicle has a tank capacity:

```
projected_range = latest_window_mileage * tank_capacity
```

### Aggregates

Lifetime and monthly aggregates run over the entries in scope (all entries, or one calendar month):

- **Total spend** = sum of `price_paid`.
- **Total distance** = odometer of the last entry in scope minus the odometer of the entry just before the scope began (so the distance driven into the month's first fill is counted in that month). When no earlier entry exists, the first entry in scope is the baseline.
- **Total quantity** = sum of `quantity`.
- **Average mileage** = total distance covered by closed full-tank windows in scope, divided by total fuel consumed in those windows. (This is a distance-weighted average, not a mean of the per-window numbers, so a long window counts more than a short one. That is the honest number.)
- **Average cost per kilometre** = total window cost divided by total window distance, over the same closed windows.

All aggregates appear from the second entry onward. Window-based figures (mileage, cost per km) appear only once a second full-tank fill exists. Until then the UI shows an empty state such as "Log one more full tank to see your mileage."

### Worked example

Three fills on a petrol car with a 35 litre tank. Prices reflect a small daily rate change.

| # | Odometer (km) | Quantity (L) | Price paid (Rs) | Full tank? |
|---|---|---|---|---|
| 1 | 10,000 | 30.00 | 3,000.00 | Yes |
| 2 | 10,250 | 15.00 | 1,509.00 | No (partial) |
| 3 | 10,600 | 25.00 | 2,515.00 | Yes |

Per-entry price per unit:

- Fill 1: 3000.00 / 30.00 = **100.00 /L**
- Fill 2: 1509.00 / 15.00 = **100.60 /L**
- Fill 3: 2515.00 / 25.00 = **100.60 /L**

Distance since previous:

- Fill 2: 10,250 - 10,000 = 250 km
- Fill 3: 10,600 - 10,250 = 350 km

Full-tank window from Fill 1 (opening full) to Fill 3 (closing full):

- Fuel consumed = fills after Fill 1 up to and including Fill 3 = 15.00 + 25.00 = **40.00 L**
- Distance = 10,600 - 10,000 = **600 km**
- Mileage = 600 / 40.00 = **15.0 km/l**
- Cost in window = 1,509.00 + 2,515.00 = **Rs 4,024.00**
- Cost per km = 4,024.00 / 600 = **Rs 6.71 /km**

Notice Fill 1's 30 litres are not counted in this window's fuel. Those litres were burned before Fill 1's odometer reading and belong to whatever came before. Fill 2, the partial, adds its 15 litres and Rs 1,509 to the window but produces no mileage number by itself.

Range:

- Range of last fill = 10,600 - 10,250 = **350 km**
- Projected range = 15.0 km/l * 35 L = **525 km**

For a CNG vehicle the same math runs with kg in place of litres, and mileage reads as km/kg. Nothing else changes.

## Fuel variant catalog

The fuel variant on an entry is optional and picked from a catalog grouped by brand. The catalog ships as a JSON asset so it can be corrected or extended (a new premium grade, a brand that changes a product name) without touching Dart code. If a brand or grade is missing, the user picks **Other** and types free text, which is stored verbatim.

The catalog covers the verified Indian products: IOCL (regular petrol and diesel, XP95, XP100, XtraGreen), BPCL (regular, Speed, Speed 97), HPCL (regular, poWer95, poWer99, poWer100, TurboJet), Shell (regular and V-Power in petrol and diesel), Nayara, Jio-bp, plus generic CNG and Auto LPG.

Structure sample:

```json
{
  "version": 1,
  "brands": [
    {
      "id": "iocl",
      "name": "IndianOil",
      "products": [
        { "id": "iocl_petrol",   "name": "Petrol",     "category": "petrol", "tier": "regular" },
        { "id": "iocl_xp95",     "name": "XP95",        "category": "petrol", "tier": "premium" },
        { "id": "iocl_xp100",    "name": "XP100",       "category": "petrol", "tier": "ultra"   },
        { "id": "iocl_diesel",   "name": "Diesel",      "category": "diesel", "tier": "regular" },
        { "id": "iocl_xtragreen","name": "XtraGreen",   "category": "diesel", "tier": "premium" }
      ]
    },
    {
      "id": "generic",
      "name": "Generic",
      "products": [
        { "id": "cng",     "name": "CNG",      "category": "cng", "unit": "kg" },
        { "id": "autolpg", "name": "Auto LPG", "category": "lpg", "unit": "litre" }
      ]
    }
  ]
}
```

The dropdown filters products to match the active vehicle's fuel category, so a diesel car only offers diesel grades plus Other. The stored value on an entry is the product `id` (or the free-text string for Other), never a display label, so a later rename of a product's display name does not rewrite history.

## Edge cases

- **First entry.** No previous entry means no distance, no mileage, no cost per km. The entry saves fine and seeds the odometer baseline. The dashboard shows the "add one more" empty state.
- **Partial-only history.** If every fill so far is a partial (the full tank toggle was turned off each time), no window has ever closed, so there is no mileage yet. Spend and quantity totals still work. The UI says so plainly rather than showing a blank or a zero.
- **Odometer correction.** Odometer must be greater than the previous entry's. If the user genuinely needs a lower value (a reading typo fixed later, or an odometer replacement), an explicit override on the form lets it through, flagged so the affected window math is transparent rather than silently wrong.
- **Vehicle switch.** Stats are always per vehicle. Windows never span two vehicles. Switching the active vehicle recomputes the dashboard from that vehicle's entries only.
- **CNG kg units.** When the vehicle's category is CNG, the quantity field label, the derived price per unit, and the mileage unit all switch to kg and km/kg. This follows from the vehicle, so the user never sets a unit by hand.
- **Editing or deleting a mid-history entry.** Because windows depend on neighbouring full fills, changing one entry can shift up to two mileage numbers. The recompute is automatic on save or delete.

## Theme and palette

This app gets used outdoors: full sun bouncing off a forecourt, a dim pump at night, rain on the screen. The palette is picked for those conditions first and for looks second.

- **Ink base.** Near-black ink (`#101418`) on a near-white surface (`#FAFAF7`) in the light theme. Maximum text contrast is what survives direct sunlight, so body text never drops to a soft grey.
- **True-black dark theme.** The dark theme uses a true black background (`#000000`) with off-white text. On OLED screens this reads cleanly at night without glare and saves a little battery.
- **Amber accent.** The single accent colour is a vivid amber (`#FFB300`), the same family as high-visibility safety gear, used for the hero numbers, the add refuel action, and selection states. It stays legible against both the ink base and true black, and it reads through a wet screen better than cool colours do.
- **Teal support.** A deep teal (`#00695C`) carries secondary structure (chips, links, the trend line) so amber keeps its meaning as "the number and the action".
- **Signal colours.** Errors use a saturated red, warnings the amber itself. Nothing meaningful is ever pale.

Rules that follow from the conditions: headline numbers are large and bold (they are read at arm's length in glare), every accent-on-base pairing must clear WCAG AA at its used size and the hero numbers aim for AAA, and no information is carried by a colour difference alone. Token names and exact values live in `lib/app/theme/colors.dart` and must match this section.

## Accessibility

- Touch targets on the add form and quick actions are at least 48 by 48 density-independent pixels, comfortably above the pump-side fumbling threshold.
- Every input has a real text label, not just a placeholder, so a screen reader announces the field and the label does not vanish once the user starts typing.
- The hero card keeps text contrast within WCAG AA (AAA for the headline numbers); the numbers do not rely on colour alone (they carry their unit as text).
- Dark and light themes are both first-class, following the system setting by default.
- Numeric fields open the number keypad and respect the device's font scaling without clipping.
