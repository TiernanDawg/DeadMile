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
- Ten biome definitions with three increasing area lengths each; area distances are scaled consistently, scenery loops through long runs, zombies pursue the vehicle with basic separation behavior, destructible road hazards deal impact damage, and supply pickups continue to spawn on longer routes.
- Ten vehicle definitions with working power/fuel/armor stats, per-vehicle upgrade tiers, local save migration for new mission counters, daily supply claim, settings, save-file sharing, achievements overview, and hidden debug panel.
- SwiftUI menus and touch controls; 50 persistent cumulative contracts with one-time cash rewards unlock after the first region, while exploration unlocks after the final region. Distance cash is calculated from displayed meters and area-clear bonuses are paid once per area. No third-party art, ROMs, ads, IAP, network runtime, JIT, or paid entitlements.

## Controls

Hold gas, reverse/brake, air tilt, and boost. Fuel pickups refill the tank; cash bundles and infected kills pay out.

## QA status and remaining work

This commit is a playable engineering prototype, not a production-complete release. The current build has not yet been verified by a successful GitHub Actions run or on-device QA. The following systems are still incomplete: ten distinct zombie archetypes with unique behaviors, hazards/obstacles, vehicle destruction and detachable parts, mounted weapons, star-grade mission scoring, an actual exploration mode and hidden kits, daily challenge validation, full biome music/engine audio, save import, and broader accessibility support. The current controls include adjustable size and a large-HUD option, but do not yet provide full remapping or Dynamic Type coverage. Do not treat definitions or unlock flags as proof those systems are implemented.
