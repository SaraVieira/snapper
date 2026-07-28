Last Edited: 28-07-2026

This is a living document of all cat stats and how they affect trust calculations in the game. It is a work in progress and will be updated as new cats are added or existing ones are modified.

---

## Overview

Each cat has five floating-point temperament traits (0.0–1.0) and two special preferences. These determine how much trust each move yields, how severe penalties are, and when certain moves become available.

---

## CatData Resource

**File:** `resources/cats/cat.gd`

| Property            | Type          | Default  | Description |
|---------------------|---------------|----------|-------------|
| `id`                | StringName    | `""`     | Unique identifier |
| `display_name`      | String        | `"Cat"`  | Name shown in-game |
| `overworld_frames`  | SpriteFrames  | —        | Sprite frames for overworld |
| `battle_portrait`   | SpriteFrames  | —        | Sprite frames for battle |
| `starting_trust`    | int (0–100)   | 0        | Initial trust when encounter begins |
| `trust_to_photo`    | int (10–100)  | 60       | Trust needed to unlock the Photo move |
| `flee_threshold`    | int (-100–0)  | -20      | Minimum trust value (cat flees below this) |
| `skittish`          | float (0–1)   | 0.5      | Affects penalty severity, Sit gain, and Pet unlock |
| `food_drive`        | float (0–1)   | 0.5      | Affects Treats gain |
| `curiosity`         | float (0–1)   | 0.5      | Affects Hand and Sound gain |
| `touch_tolerance`   | float (0–1)   | 0.5      | Affects Pet gain |
| `favourite`         | enum          | `treats` | Doubles gain for this move on hit |
| `hates`             | enum          | `sound`  | Always applies hated penalty regardless of hit/miss |
| `nocturnal`         | bool          | false    | Cat is nocturnal |

`favourite` and `hates` options: `pet`, `hand`, `treats`, `sound`, `sit`

---

## Trust Formulas

### Gain (on hit)

Trust is gained when a move hits and the cat does not hate it.

| Move    | Formula                          |
|---------|----------------------------------|
| Pet     | `8 + 14 × touch_tolerance`       |
| Hand    | `6 + 10 × curiosity`             |
| Treats  | `5 + 18 × food_drive`            |
| Sound   | `4 + 12 × curiosity`             |
| Sit     | `3 + 9 × skittish`               |

If the move matches the cat's `favourite`, the result is **doubled**.

### Penalty (on miss)

Trust is lost when a move misses (and the cat does not hate it).

| Move    | Formula                             | Notes |
|---------|-------------------------------------|-------|
| Pet     | `-(4 + 12 × skittish) × 1.5`        | Touching a cat that isn't ready is worse |
| Hand    | `-(4 + 12 × skittish)`              | |
| Treats  | `-(4 + 12 × skittish)`              | |
| Sound   | `-(4 + 12 × skittish)`              | |
| Sit     | `0`                                 | Sit has no penalty for missing |

### Hated penalty

If the cat hates the chosen move, this penalty is always applied — even on a hit. It overrides and replaces any other outcome.

| Formula                       |
|-------------------------------|
| `-(6 + 10 × skittish)`       |

### Final trust

After every move, trust is clamped to `[flee_threshold, 100]`:

```
trust = clamp(trust + delta, flee_threshold, 100)
```

---

## Availability

Some moves are locked based on current trust:

| Move  | Condition                              | Default threshold |
|-------|----------------------------------------|-------------------|
| Photo | `current_trust >= trust_to_photo`      | 60                |
| Pet   | `current_trust >= 40 × skittish`       | varies by cat     |
| All others | Always available                  | —                 |

Locked moves are dimmed in the menu and skipped during menu navigation.
