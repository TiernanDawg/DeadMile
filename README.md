# DEAD MILE

Original 2D zombie-driving arcade game for iPhone. Native SwiftUI + SpriteKit, procedural Core Graphics sprites, local Codable save, biome/area definitions, and an unsigned IPA GitHub Actions workflow.

## Build

```bash
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project DeadMile.xcodeproj -scheme DeadMile -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions packages the device app into an unsigned `DeadMile.ipa`. Sign it with a sideloading tool before installing on a standard iPhone.

## Included

- SpriteKit driving scene with dynamic chassis and pin-jointed wheels, seeded terrain profile, zombie contact handling, pickups, fuel, health, boost, and distance/kills payout.
- Procedural Core Graphics vehicle and zombie sprites.
- Ten biome definitions with three increasing area lengths each.
- Ten vehicle definitions, upgrade tiers, local save, daily supply claim, settings, achievements overview, and hidden debug panel.
- SwiftUI menus and touch controls; no third-party art, ROMs, ads, IAP, network runtime, JIT, or paid entitlements.

## Controls

Hold gas, reverse/brake, air tilt, and boost. Fuel pickups refill the tank; cash bundles and infected kills pay out.

## QA status and remaining work

This commit is a playable engineering prototype, not a production-complete release. The current build has not yet been verified by a successful GitHub Actions run or on-device QA. The following brief requirements are not complete: all ten zombie archetypes and their unique AI, full 30-area progression and unlock flow, hazards/obstacles, vehicle destruction and detachable parts, mounted weapons, mission objective/star tracking, exploration mode and hidden kits, daily challenge validation, full biome music/engine loop, save import, and the requested accessibility/control customization. Do not treat the listed definitions or menu entries as proof those systems are implemented.
