# DEAD MILE

**Dead Mile** is an original, offline-first, side-scrolling zombie-driving campaign for iPhone. It takes inspiration from the fuel-limited, earn-cash, upgrade-and-drive loop of classic zombie vehicle games, while using its own name, vehicles, art, scenery and stage designs.

## Campaign

- 10 regions × 3 legs = **30 campaign legs** with increasing distance and difficulty.
- Each leg ends at an extraction marker. Complete the full route to unlock the next leg; clear the final leg of a region to open the next region.
- Every leg has changing elevation, a raised bridge section, a lowered tunnel section, roadside hazards, zombie groups and a midway fuel-service stop.
- The midway checkpoint restores part of the tank and awards cash. It is a real in-run event, not just a menu marker.
- Runs end when the vehicle is wrecked or runs out of fuel. Distance, kills, pickups and destroyed roadblocks contribute to the payout.

## Driving and combat

- SpriteKit physics scene with a dynamic chassis, independently rotating wheels, wheel torque plus engine traction, persistent momentum, braking/reversing and airborne pitch control.
- Engine health affects power. Chassis damage can detach body panels and a wheel; repair is automatic between runs.
- Zombies have dynamic bodies and ragdoll knockback. A high-speed hit can launch them; lower-speed impacts push them back and can damage the vehicle.
- Six physical roadside obstacle types: crates, boulders, spike barricades, fuel drums, wrecked cars and concrete barriers. They move on impact and require repeated impacts to break.
- Mounted weapon, boost, fuel, repair and cash pickups. Ten original vehicle designs have different mass, power, armor, fuel capacity and purchase prices.

## Garage and progression

Six upgrade systems, each with five tiers and vehicle-specific levels:
1. **Engine** — acceleration and top speed.
2. **Tires** — grip and traction.
3. **Fuel tank** — greater range.
4. **Armor** — hull capacity.
5. **Boost** — stronger and longer nitro.
6. **Weapon** — faster mounted-weapon fire.

Cash is earned from distance, zombie kills, destroyed roadblocks and pickups. There are no ads, paid currency, forced video rewards, accounts or online services. Local progress is saved as Codable JSON. The existing 50 contracts, daily challenge, achievements, import/export, audio/haptic settings and free-roam unlock remain.

## Controls

- Gas and brake/reverse.
- Separate left/right airborne pitch controls.
- Boost and optional mounted-weapon fire.
- External controller: right trigger = gas, left trigger = brake, left stick = pitch, B = boost, A = fire.
- Adjustable control size and mirrored left-handed layout.

## Build

The repository uses SwiftUI + SpriteKit, XcodeGen and GitHub Actions on the `xcode-27` runner. The workflow builds an unsigned iOS 27 ARM64 app and packages it as `DeadMile.ipa`. Download the workflow artifact and sign it with SideStore or another sideloading tool before installing.

```bash
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project DeadMile.xcodeproj -scheme DeadMile -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Art and licensing

All app artwork is original procedural/vector art in the repository. The game recreates genre mechanics, not Earn to Die's name, logo, characters, vehicle artwork, UI assets, sound or proprietary content.

## QA status

The 30-leg campaign and garage overhaul compiled successfully with Xcode 27.1 / iOS 27.1 SDK and produced a verified unsigned ARM64 IPA in GitHub Actions (run 42543817762, commit 5ff483441ce4aa894578f8d51e9f8aeb196f667b). The downloaded archive and nested IPA passed ZIP integrity checks; the app bundle ID is `com.tiernan.deadmile` and its minimum OS is iOS 27.0. This verifies compilation and packaging only—not real-device driving feel, collisions, frame pacing, or economy balance. Hands-on testing on the iPhone 17 Pro is still required.
