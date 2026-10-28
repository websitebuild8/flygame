# Buoy challenges, XP and levels

Open **Goals (gold trophy) → Spots**, or approach a fishing buoy and tap
**Buoy challenges**. Choose a challenge, read its goals and press Start. Nothing
starts automatically. Start requires the correct unlocked buoy within 14 world
units, a stopped boat, neutral or engine off, and no fish currently on the line.
Night challenges require 18:00–06:00 game time. Only one attempt can run at a time.

## Permanent goals

| Point | Goal | First-clear base XP / MVR |
|---|---|---|
| Kelaa Lagoon | Land three fish | 60 / 80 |
| Kelaa Outer Reef | Land a giant trevally of at least 5 kg | 90 / 110 |
| Vashafaru Channel | Land two fish of different species | 80 / 100 |
| Filladhoo Dropoff | Land a mahi-mahi | 100 / 130 |
| Haa Alif Bluewater | Land a sailfish | 160 / 250 |
| Baarah Drift | Land two fish at night | 100 / 130 |
| Dhidhdhoo Reef | Land at least two species totalling 12 kg | 120 / 160 |

One star means completion. Higher stars use the average qualifying specimen
weight, or combined weight for a combined-weight challenge. Exact thresholds are
shown before starting. Best stars persist and never decrease on a weaker replay.

## Three optional timed events

- Lagoon dash: two catches in three minutes, level 2.
- Reef rush: three catches in five minutes, level 3.
- Channel sprint: at least 10 kg in five minutes, level 4.

Three stars require at least 60% time remaining; two stars require 33%; one star
requires finishing before zero. The HUD shows the active countdown/progress.
Timers advance with gameplay time, not wall-clock time. Settings, Goals, the chart,
catch information and focus loss pause the timer. Leaving the 18-unit point area,
ending an attempt or timing out produces a failure result. Fish and catch XP remain.
Retry is free. An unfinished attempt needs a second confirmation before cancellation.

An active session saves remaining time, accepted catches, species and weight, plus
the boat's position/yaw. Reload resumes safely at the point with the engine off.
The current hooked fish is not reconstructed; it was not a landed catch. Invalid
saved positions end the attempt without confiscating inventory. These are offline
challenges, not secure online competitions.

## Rewards and XP

Claim a successful result in Spots. Its rewards and cleared result are saved with
the balance/XP in the existing trip save. First-clear MVR pays once. First-clear XP
is the listed base plus 20 per star above bronze. Replays pay 10 XP, plus 20 XP for
each improved star; they do not repeat first-clear MVR. Pending rewards remain
claimable after leaving the point or restarting, and must be claimed before a new
attempt starts. Stars and medal UI reuse native 2D geometry and existing medal art.

Every newly landed fish earns 20 XP plus up to 15 weight XP. New discoveries add
40 XP and personal weight records add 20 XP. Harbour contract claims add 60 XP;
weekly claims add 120 XP. Legacy saves receive 20 XP per already recorded lifetime
catch once when the XP field is absent. This does not invent species records or
weekly progress. Subsequent saves persist explicit cumulative XP.

Level 1→2 costs 100 XP; each later step costs 50 more, up to level 20. The HUD XP
bar animates on gains, catch screens show XP/level-up messages and the Club shows
rank. Free cosmetic gifts unlock automatically at levels 5 (Reef bronze), 10
(Atoll silver) and 15 (Ocean gold). Apply them through shop Customise. These are
separate from the planned real-money premium collection and do not change stats.

## Validation and limits

The spot challenge tests cover level/location/weight/species/night gates, gameplay
clock advance, pause/focus loss, timeout, best stars/replay rewards, save/reload at
the buoy, actual landed-catch integration, one-time cash/XP claims and free gifts.
Existing progression, visual HUD, cosmetic, menu, fight, landing, market and haptic
checks provide regression coverage. Screens are rendered for visual checks.

Goal thresholds and payouts are initial game balance and need phone playtesting.
No new 3D assets, downloaded textures, native billing or online services are added.
