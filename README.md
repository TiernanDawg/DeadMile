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

- SpriteKit driving scene with dynamic chassis and pin-jointed wheels, seeded terrain profile, ten zombie archetypes with differentiated movement/weight, upgrade-powered mounted weapons, projectile combat, zombie contact handling, vehicle damage and detachable wheel behavior, road hazards, pickups, fuel, health, boost, and distance/kills payout.
- Procedural Core Graphics vehicle and zombie sprites.
- Ten biome definitions with three increasing area lengths each; area distances are scaled consistently, scenery loops through long runs, zombies pursue the vehicle with basic separation behavior, three road-hazard types deal impact damage, scenery loops through long runs, and fuel/cash/boost/repair supplies continue to spawn.
- Ten vehicle definitions with working power/fuel/armor stats, per-vehicle upgrade tiers, versioned local saves with validated JSON import/export and sharing, local-time daily supply claims, settings, achievements, and hidden debug panel.
- SwiftUI menus and touch controls; 50 persistent cumulative contracts with one-time cash rewards and up to three saved stars unlock after the first region. A rotating daily challenge tracks distance, kills, or supplies and pays a one-time reward. Completing the final region unlocks long-form free roam with collectible survival caches. Procedural engine and biome ambience loops supplement impact and pickup audio. Distance cash is calculated from displayed meters and area-clear bonuses are paid once per area. No third-party art, ROMs, ads, IAP, network runtime, JIT, or paid entitlements.

## Controls

Hold gas, reverse/brake, air tilt, and boost. Fuel pickups refill the tank; cash bundles and infected kills pay out.

## QA status and remaining work

This commit is a playable engineering prototype, not a production-complete release. Xcode 27 device builds and unsigned IPA packaging have passed in GitHub Actions, including the ten-zombie, weapon, exploration, save-import, and VoiceOver-control implementation. The newest daily-challenge, mission-star, damage, and audio refinements are still awaiting their own build verification. No on-device gameplay QA has been completed. Remaining work includes broader control remapping, additional enemy and vehicle-part behaviors, richer biome music, and device-level performance/balance testing. The current controls include adjustable size and a large-HUD option, but do not yet provide full remapping or Dynamic Type coverage. Do not treat definitions or unlock flags as proof those systems are implemented.
