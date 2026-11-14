# Bangla Gravity

A 3D cartoon-style crazy physics platform game built with Godot 4.2+.

## Implemented prototype features
- 3D obstacle-course gameplay, character movement, jumping and physics collisions
- Rotating hazard and elevated stepping platforms
- 100-stage procedural difficulty progression
- Level clear rewards: 100 base coins plus a speed bonus
- Persistent local save for level progress, unlocked levels, coins and abilities
- Double Jump ability: unlock permanently for 250 coins
- Android touchscreen movement and jump controls
- Experimental ENet multiplayer over the same Wi-Fi/LAN: host on port 8910; other devices enter the host's local IP and press Join; up to four connected clients are accepted

## Controls
- WASD / Arrow keys: Move
- Space: Jump
- Android touchscreen: On-screen directional buttons and Jump button
- Clear a level to unlock the next one; progress saves locally
- Collect coins and purchase Double Jump from the HUD

## Multiplayer notes
The current networking code is an early LAN synchronization prototype, not a finished competitive multiplayer system. It synchronizes player positions and displays remote player markers; gameplay physics, level state, rewards and anti-cheat are not yet server-authoritative. Both devices should be on the same Wi-Fi network, and the host firewall must allow UDP port 8910.

Internet matchmaking/servers and Bluetooth multiplayer are not implemented. Bluetooth support needs a separate Android-native transport; internet multiplayer needs a reachable dedicated/relay server or suitable network configuration. Do not treat the current LAN prototype as Play Store release-ready.

## Run and test
1. Install Godot 4.2 or newer.
2. Import this folder (project.godot) in Godot.
3. Press F5 to run the main scene.
4. Test offline first. For LAN, run two game instances/devices on the same Wi-Fi; Host on one and Join using its local IP on the other.

Android touch controls, rewards, saving and multiplayer still require actual Godot runtime and device testing. This repository update has not been executed in Godot in this environment, and no APK has been built.

## Planned next
- Individually designed 100+ levels and boss stages
- Full online multiplayer, Bluetooth transport and room/lobby UI
- More unlockable abilities, skins, secret characters and reward types
- Additional worlds, sound, settings and Play Store export/signing

## License
MIT. See [LICENSE](LICENSE).
