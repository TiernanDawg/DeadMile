# DEAD MILE

Original 2D zombie-driving arcade game for iPhone. Native SwiftUI + SpriteKit, original procedural Core Graphics/SpriteKit artwork, a physics-driven side-view vehicle, local Codable saves, ten biome definitions, and an unsigned IPA GitHub Actions workflow.

## Build

```bash
brew install xcodegen
xcodegen generate --spec project.yml
xcodebuild -project DeadMile.xcodeproj -scheme DeadMile -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions packages the device app into an unsigned `DeadMile.ipa`. Sign it with a sideloading tool before installing on a standard iPhone.

## Included

- SpriteKit driving scene with a dynamic chassis, powered pin-joint wheels, separate chassis/wheel/terrain collision layers, camera framing that keeps the vehicle clear of touch controls, ground-aligned spawning, a broad asphalt road with lane markings, terrain-following physics, and speed-matched wheel rotation.
- Ten distinct procedural vehicle silhouettes and ten zombie visual archetypes. Infected have differentiated movement, mass and durability; mounted weapons fire projectiles; road hazards damage the vehicle; severe damage can detach the hood and a wheel.
- Original layered wasteland scenery: distant mesas, abandoned skyline, dead trees, utility poles, parallax scrolling, biome palettes, roadside debris, and a vector-drawn menu background. No third-party art pack or licensed game assets are used.
- Ten biome definitions with three increasing area lengths each; scenery loops across long runs, zombies pursue and separate from each other, three road-hazard types deal impact damage, and fuel/cash/boost/repair supplies spawn along the route. Missed pickups and other off-screen entities are culled.
- Ten vehicle definitions with working power/fuel/armor stats, per-vehicle upgrade tiers, versioned local saves with validated JSON import/export and sharing, local-time daily supply claims, settings, achievements, and hidden debug panel.
- SwiftUI menus and touch controls; 50 persistent cumulative contracts with one-time cash rewards and up to three saved stars unlock after the first region. A rotating daily challenge tracks distance, kills, or supplies and pays a one-time reward. Completing the final region unlocks long-form free roam with collectible survival caches. Procedural engine and biome ambience loops supplement impact and pickup audio. Distance cash is calculated from displayed meters and area-clear bonuses are paid once per area. No third-party art, ROMs, ads, IAP, network runtime, JIT, or paid entitlements.

## Controls

Touch controls use press/release handling, on-control labels, adjustable size, a compact HUD with numeric meters, and mirrored left-handed placement. The garage and home screen are fitted for landscape layouts. Compatible external controllers use right trigger for gas, left trigger for brake, left stick for tilt, B for boost, and A for fire. Fuel pickups refill the tank; cash bundles and infected kills pay out.

## QA status and remaining work

The latest source successfully compiled with Xcode 27.1 against the iOS 27.1 SDK and produced a verified unsigned ARM64 IPA in GitHub Actions (run 41554957310). The IPA has not yet been installed or play-tested on a physical iPhone. The driving/physics changes are intended to correct the previous weak road contact, off-screen car framing, and unreliable touch input, but real-device handling, collisions, frame rate, and balance still need hands-on QA. Remaining work includes fuller control remapping, broader accessibility/Dynamic Type support, more biome-specific environmental props/music, and on-device performance/balance testing. Do not treat definitions or unlock flags as proof those systems are implemented.
