# Fishing progression

Tap the gameplay HUD’s **book** or **gold trophy** icon to open **Angler’s Club**.
Collection, Contracts and Weekly have dedicated illustrated screens, with medals
and progress bars. The Club pauses gameplay and returns directly to fishing. See
[visual UI notes](gamified-ui.md).

## Collection and personal records

Each of the five imported species gets a permanent journal entry on landing.
Track catch count, total landed weight, biggest specimen, highest individual sale
value and the spot where the weight record was caught. The catch information
screen announces new species and new personal bests. Mastery labels unlock at
1 (Discovered), 5 (Skilled angler) and 15 (Master angler) landed fish.

The journal lists actual game fishing spots and their catch-milestone requirements.
It also explains each species' fictional game behaviour. No real-world fishery or
market-price claims are made. Historical catch sizes that were never saved cannot
be reconstructed: old saves seed known fish still in their inventory only.

## Harbour contracts

A safely berthed player may accept one of three rotating offers. A contract names
one species, a minimum fish count, a minimum combined weight and the accepting
harbour. Selling matching fish to that harbour's market advances it. Existing fish
already aboard can be delivered; these are delivery orders, not catch-after-accept
quests. Selling at another island or selling another species does not advance it.

Ordinary fish payment and pending cash recovery remain unchanged. Contract progress
is saved in the same write that removes the delivered fish and records pending cash.
Claim the separate earned-MVR bonus at the specified harbour, once. Completion
rotates the offers. One active contract can be abandoned; partial progress is lost,
with no fee. Early offers use starter-water species; mahi-mahi joins after three
completed contracts and sailfish after six. Bonus amounts are fictional game balance.

## Optional weekly challenge

Land 10 fish across at least three species to earn MVR 300. Claim once at any safe
harbour berth. There is no daily login streak or penalty for missing a day. The
challenge resets Monday UTC using the device clock. Records and contracts persist
across resets. This is an offline feature and is not a tamper-proof online contest.

## Different fish fights

Existing casting, hook timing, rod/reel geometry, retrieval inputs, landing safety
and upgrade stat bonuses are retained. Species now select different timing and
movement profiles: steady long tuna runs, shorter trevally pulls, quick skipjack
darts, wide sailfish runs/leaps, and faster mahi-mahi turns/leaps. These are game
balance/art-direction choices. Profiles reuse existing movement/splash systems;
they add no new 3D assets or per-frame scene objects.

## Save and validation

The existing trip save gains a versioned progression dictionary. Known species,
numeric bounds and harbour names are validated. Catches are recorded once at the
successful landing transition; repeated land calls cannot double-count. Contract
and weekly reward claims clear/set their state before saving the increased balance.
Legacy balances, fish inventory, gear and boat ownership remain intact.

`tests/trip_progress_checks.gd` covers discoveries, records, mastery, contract
filters and weight/count conditions, one-time claims, offer rotation, weekly reset,
save/reload, legacy migration, real market payments, catch celebrations, menu
navigation and distinct species movement profiles. Existing fishing/market/menu/
cosmetic checks provide regression coverage. Real-device performance still needs
checking; no extra texture downloads, 3D models, account system or ads are added.
