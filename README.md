# ISP Router Toolkit

A Flutter/Android app giving field technicians one unified interface for
common customer-router tasks (Wi-Fi name/password, PPPoE, connected
devices, reboot), regardless of router manufacturer.

## Status: Phase 1 + Phase 2 foundation

This delivers the architecture and UI end-to-end, wired against a fully
working **GenericAdapter** (for structural testing) and a **TP-Link
Archer C6 adapter skeleton** whose fingerprinting is real but whose
authentication/settings calls are intentionally left unimplemented.

**Why the TP-Link adapter isn't "finished":** per the project's own rule
(spec section 25 — "do not pretend a feature works when the router's
actual protocol has not been determined"), I didn't guess at TP-Link's
login/settings payload shapes. Guessing wrong here isn't a cosmetic bug —
it can silently corrupt a customer's router config. See
`lib/routers/tplink/tplink_archer_c6_adapter.dart` for exactly what's
needed to finish it (capture real traffic from a browser session against
a physical Archer C6, e.g. via a local HTTPS-capable proxy, to confirm
the login endpoint, payload/encryption scheme, and session transport).

Once that's confirmed, filling in the `TODO`s there is the only work
needed — no other file changes, because the UI and RouterManager only
ever talk to the `RouterAdapter` interface.

## What's implemented

- Full app shell: Discovery → Authenticate → Dashboard → Wi-Fi/PPPoE/
  Devices/Admin screens, Material 3, light + dark theme
- `RouterAdapter` interface + `RouterManager` orchestrator (identification,
  credential-list auth loop, manual fallback, capability gating)
- `GenericAdapter` (safe no-op fallback for unidentified routers)
- TP-Link Archer C6 adapter: real fingerprinting, stubbed auth/settings
- Encrypted local storage (Android Keystore via `flutter_secure_storage`)
  for the configurable admin-password list and admin PIN
- Sanitized logging (`SafeLogger`) that redacts password-shaped fields
  by construction, not by convention
- Gateway/SSID/subnet detection via `network_info_plus` + `connectivity_plus`
- Full error-state coverage matching spec section 21 (no Wi-Fi, gateway
  unreachable, unsupported router, auth failure, save failure)
- Unit tests for adapter contract behavior and model logic

## What's intentionally not implemented yet

- Any real TP-Link (or other manufacturer) authentication/settings
  read-write — see above
- Netis/Tenda/TOTOLINK/Xiaomi/Huawei/ZTE adapters (Phase 6/7)
- Client-records integration (section 19 — explicitly "not v1")
- Per-adapter enable/disable persistence in Admin Settings (currently
  a read-only preview list)
- Speed test (explicitly out of scope for v1 per spec)

## Getting started

```bash
flutter pub get
flutter run
```

Requires a physical Android device or emulator connected to a Wi-Fi
network with a reachable gateway (emulators typically only expose a
virtual gateway at `10.0.2.2`, so real device testing against an actual
router is recommended once an adapter is implemented).

## Architecture

```
UI (screens/)
   ↓ (via Provider)
RouterManager                  ← the only class screens depend on
   ↓
RouterAdapter (interface)
   ├── GenericAdapter          ← safe fallback, always available
   ├── TpLinkArcherC6Adapter   ← fingerprinting done, protocol TODO
   └── (future) NetisAdapter, TendaAdapter, ...
```

Adding a manufacturer = implementing `RouterAdapter` + registering it in
`RouterManager._registerAdapters()`. No screen ever needs to change.

## Security notes

- Router/Wi-Fi/PPPoE credentials never leave the device — all
  communication is directly phone ↔ router over the LAN
- All secrets at rest go through `SecureStorageService`
  (Android Keystore-backed `EncryptedSharedPreferences`)
- `SafeLogger` strips any field whose key looks password-shaped before
  it's ever written to a log line
- Passwords are masked by default in the UI; reveal requires an explicit
  tap (`SettingRow`)
- `usesCleartextTraffic="true"` is required in the Android manifest
  because most router admin UIs are plain HTTP on the LAN — this does
  not enable cleartext to the public internet, only to the local gateway.
  Consider a `network_security_config.xml` scoping this to private IP
  ranges if you want it locked down further.

## Testing

```bash
flutter test
```

Covers: `GenericAdapter` contract behavior, a `FakeAdapter` exercising
the auth/settings flow shape, and model edge cases (unknown router
naming, unknown device naming). Real per-manufacturer adapter tests
should be added alongside each adapter once its protocol is confirmed —
mock the HTTP layer (e.g. with `dio`'s `DioAdapter` test double) rather
than hitting a live router in CI.
