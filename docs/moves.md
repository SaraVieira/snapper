Last Edited: 28-07-2026

This is a living document of all the moves available in the game. It is a work in progress and will be updated as new moves are added or existing moves are modified.

---

## Pet

**File:** `battle/pet/pet.gd`

Pet is supposed to be the strongest one, but it is also the hardest to hit. It is locked until the cat's trust reaches `40 × skittish`.

**Minigame:** A marker sweeps back and forth horizontally across a bar divided into three zones (from center outward):

| Zone    | Hit chance |
|---------|-----------|
| Green   | 80%       |
| Yellow  | 40%       |
| Red     | 20%       |
| Outside | 0%        |

Pressing Space stops the marker. The hit chance is the zone the marker lands in.

**Trust effect:** On hit, trust increases based on the cat's `touch_tolerance`. On miss, trust decreases at 1.5× the standard penalty (touching a reluctant cat is worse). Pet is locked until the cat's trust reaches `40 × skittish`.

---

## Hand

The idea of hand is that you just extend your hand, and the cat can choose to sniff it or not. It basically depends on the cat's curiosity. 

**File:** `battle/hand/hand.tscn`

**Status:** Placeholder — no minigame implemented yet.

**Trust effect:** On hit, trust increases based on the cat's `curiosity`. Standard miss penalty.

---

## Treats

Treats 

**File:** `battle/treats/treats.tscn`

**Status:** Placeholder — no minigame implemented yet.

**Trust effect:** On hit, trust increases based on the cat's `food_drive`. Standard miss penalty.

---

## Sound ("Pss Pss")

**File:** `battle/sound/sound.gd`

**Minigame:** Three colored bars (red, yellow, green) each have a shader-driven fill that oscillates between 0.0 and 1.0. Press Space once per bar to lock its value — red first, then yellow, then green. On the third press (green), the attack resolves.

**Hit calculation:** `randf() < (red_value + yellow_value + green_value) / 3` — higher locked values mean better odds. A "Hit!" or "Miss!" label is displayed for 2 seconds.

**Trust effect:** On hit, trust increases based on the cat's `curiosity`. Standard miss penalty.

---

## Sit

**File:** `battle/sit/sit.tscn`

**Status:** Placeholder — no minigame implemented yet.

**Trust effect:** On hit, trust increases based on the cat's `skittish`. No penalty on miss — sitting is the safest move.

---

## Photo

**File:** `battle/photo/photo.tscn`

**Status:** Placeholder — no minigame implemented yet.

**Availability:** Locked until the cat's trust reaches `trust_to_photo` (default 60). This is the end-game move — only available once the cat trusts you enough.
