# WIN68HE Calibration Protocol

## Scope

This document reconstructs the WIN68HE calibration flow used by the AULA web app.

Primary sources:

- `agreement.min.js`: HID writers and HID input parser
- `wmIndex.pretty.js`: calibration UI flow and highlighted-key rendering
- `assets/devices/win68he_layout.json`: logical key index map for WIN68HE
- HID capture recorded on April 25, 2026: used as validation, not as the only source

Confidence labels used below:

- Confirmed: directly implemented in vendor JavaScript
- Validated: confirmed in vendor JavaScript and matched by the HID capture
- Inferred: seen in HID capture but not yet located in vendor JavaScript

## Transport

- `reportId = 1`
- payload length = `63` bytes
- heartbeat/status family = `0x01`
- trigger and calibration family = `0x21`
- calibration-related packets use `data[4] = 0x18`

For calibration, the minimum packet shape is:

```text
byte 0  = 0x21
byte 4  = 0x18
byte 5  = command opcode
byte 6+ = command payload
```

## Confirmed write commands

| Purpose | Bytes | Confidence | Source |
| --- | --- | --- | --- |
| Legacy per-key calibration target | `21 00 00 00 18 07 <group> <offset>` | Confirmed packet shape, unverified live flow | `agreement.min.js -> reviseKey()` |
| Start selected-key calibration | `21 00 00 00 18 08 00` | Confirmed | `wmIndex.pretty.js -> reviseKeys(0x08, 0x00)` |
| Stop selected-key calibration | `21 00 00 00 18 08 01` | Confirmed | `wmIndex.pretty.js -> reviseKeys(0x08, 0x01)` |
| Start any-key calibration | `21 00 00 00 18 0f 00` | Confirmed | `wmIndex.pretty.js -> reviseKeys(0x0f, 0x00)` |
| Stop any-key calibration | `21 00 00 00 18 10 00` | Confirmed | `wmIndex.pretty.js -> reviseKeys(0x10, 0x00)` |
| Set poll rate | `21 00 00 00 00 09 01 <pollRate>` | Confirmed | `agreement.min.js -> setPollRate()` |

The app also uses the same `0x21` family for trigger-table writes:

- `setAnyTriggerValue(...)` packs a 31-byte payload into the `0x21` family.
- This is not the calibration start flow, but it confirms the same key-index encoding used by calibration.

## Selected-key mode in the downloaded site build

This needs an important correction.

`agreement.min.js` does define:

```text
21 00 00 00 18 07 <group> <offset>
```

through `reviseKey()`, but in the downloaded site build we have not found any call site that uses it during the calibration UI flow.

What the current UI actually does is:

1. enter the calibration tab
2. click the `reviseKeys` button
3. send `21 00 00 00 18 08 00` for legacy selected-key mode, or `21 00 00 00 18 0f 00` for any-key mode
4. wait for physical key presses
5. paint completed keys blue from progress packets
6. stop with `21 00 00 00 18 08 01` or `21 00 00 00 18 10 00`

Evidence:

- `wmIndex.pretty.js -> _0x5dd167()` clears all on-screen checked states before starting calibration.
- `site.html` calibration instructions say:
  - click start
  - press the keys that need calibration
  - wait for the corresponding keys to turn blue
  - click stop
- `rg` over the downloaded JS finds the `reviseKey()` definition, but no active call site in the calibration flow.

Current interpretation:

- `0x08` mode in this site build is not "select keys on the UI, then send them".
- It behaves more like "start a legacy calibration session and let the user physically choose which keys to calibrate by pressing them".
- `0x07` is therefore confirmed as a valid packet shape, but not confirmed as part of the live calibration flow exposed by this specific site build.

For app work, treat this as:

- `0x08 00` / `0x08 01`: confirmed selected-session control
- `0x07 <group> <offset>`: confirmed packet format, but currently unverified in the visible end-to-end flow

## Inferred pre-flight command

The HID capture contains a command before `0x0f`:

```text
21 00 00 00 18 03 00
```

Current status:

- confidence: Inferred
- seen in capture immediately before `21 ... 18 0f 00`
- not yet located in the downloaded vendor JavaScript

Working interpretation:

- likely a pre-flight or arm-session command
- do not implement it as required protocol until we find the vendor call site or reproduce a failure without it

## Key addressing

### Per-key command address

The vendor JavaScript addresses a key with:

```text
group  = floor(index / 22)
offset = index % 22
```

This is the payload used by `0x07`.

Example:

- `Esc` has `index = 22`
- `group = 1`
- `offset = 0`
- packet: `21 00 00 00 18 07 01 00`

### Progress bitmap encoding

Calibration progress is returned as a 22-byte bitmap in `data[7..28]`.

The site decodes it with:

```text
for byteIndex in 0..21:
  for bitIndex in 0..5:
    if bit is set:
      keyIndex = 22 * bitIndex + byteIndex
```

This is the inverse of the same `group/index` scheme:

- byte position = `offset`
- bit position = `group`

### Why the bitmap uses 22 bytes x 6 bits

`assets/devices/win68he_layout.json` contains `68` physical keys, but the index space is sparse:

- minimum index = `22`
- maximum index = `126`

That requires six 22-key groups:

- group 0 -> indices `0..21`
- group 1 -> indices `22..43`
- group 2 -> indices `44..65`
- group 3 -> indices `66..87`
- group 4 -> indices `88..109`
- group 5 -> indices `110..131`

The device reports the whole sparse logical space even though only part of it is populated on WIN68HE.

## Confirmed input parser

The vendor parser handles calibration responses here:

- `agreement.min.js -> readHidData()`

Branch:

```text
reportId == 1
data[0] == 0x21
data[5] == 0x08 || data[5] == 0x0f
```

Interpretation:

- `data[5]` selects the calibration mode
  - `0x08` = selected-key mode
  - `0x0f` = any-key mode
- `data[6]` is the session status code

### Status codes

| `data[6]` | Meaning | Confidence | UI effect in vendor app |
| --- | --- | --- | --- |
| `0x00` | Terminal success | Confirmed | stops calibration, removes tip, resets button, shows success alert |
| `0x01` | Progress snapshot | Confirmed | decodes bitmap from `data[7..28]`, calls `refreshReviseKeys(...)`, paints keys blue |
| `0x02` | Terminal failure or abort | Confirmed | stops calibration, resets button, shows failure alert |
| `0x04` | Terminal failure or abort | Confirmed | stops calibration, resets button, shows failure alert |

Important detail: the vendor app does not expose a dedicated "one key completed" opcode. It only receives progress snapshots and terminal states.

## What the blue keys mean

`wmIndex.pretty.js -> refreshReviseKeys(...)`:

- clears the previous calibration highlight
- finds each device key by logical index
- paints the matching keys blue

That means the progress bitmap is the set of highlighted or accepted keys for the current calibration session.

For app code, the most useful field name is:

- `completedKeyIndices`

instead of:

- `activeKeyIndices`

This matches the calibration instructions in the HTML better than a "selected keys before start" model:

- the user starts calibration first
- then physically presses whichever keys they want to calibrate
- the device returns completed keys as the blue-highlight bitmap

## Validation against the captured HID log

The captured any-key session contains these progress packets:

```text
2026-04-25T17:41:47.806Z  21 00 00 00 18 0f 01 00 00 ...
2026-04-25T17:41:49.483Z  21 00 00 00 18 0f 01 02 00 ...
2026-04-25T17:41:50.693Z  21 00 00 00 18 0f 01 02 02 ...
2026-04-25T17:41:51.517Z  21 00 00 00 18 10 00 ...
```

Decoded with the confirmed bitmap parser:

1. `21 ... 18 0f 01 00 00 ...`
   - completed keys = `[]`

2. `21 ... 18 0f 01 02 00 ...`
   - byte 0 = `0x02`
   - set bit = group `1`
   - index = `22 * 1 + 0 = 22`
   - completed keys = `[22]`
   - `win68he_layout.json` index `22` = `Esc`

3. `21 ... 18 0f 01 02 02 ...`
   - byte 0 = `0x02` -> index `22`
   - byte 1 = `0x02` -> index `23`
   - completed keys = `[22, 23]`
   - `win68he_layout.json` indices `22, 23` = `Esc`, `1!`

This gives us both validations requested by the plan:

- one-key progress validation: `[22]`
- two-key progress validation: `[22, 23]`

## Recommended app state machine

Device packets do not directly emit every UI state we want. The clean split is:

- raw protocol state: what the keyboard actually reports
- app session state: what Flutter should expose upstream

### Raw protocol state

- start selected-key mode -> `0x08 0x00`
- stop selected-key mode -> `0x08 0x01`
- start any-key mode -> `0x0f 0x00`
- stop any-key mode -> `0x10 0x00`
- progress -> `data[6] == 0x01`
- success -> `data[6] == 0x00`
- abort or failure -> `data[6] == 0x02 || data[6] == 0x04`

### App session state

- `idle`
  - no session in progress
- `arming`
  - local state after sending start, before the first matching progress packet
- `running`
  - at least one `data[6] == 0x01` packet received
- `key_completed`
  - synthesized by the app when `completedKeyIndices` grows between two progress packets
- `finished`
  - terminal `data[6] == 0x00` without a local cancel request
- `aborted`
  - terminal `data[6] == 0x02 || data[6] == 0x04`
  - or terminal `data[6] == 0x00` after the app had already requested cancel or stop
- `timeout`
  - synthesized by the app if the session stalls and no terminal packet arrives within a policy timeout

## Recommended Flutter-facing interfaces

The app should expose three protocol-facing models:

- `CalibrationCommand`
- `CalibrationProgress`
- `CalibrationSessionState`

The shape implemented in this repository is available in:

- `docs/reference/win68he_calibration_protocol.dart`

That file includes:

- command builders for `0x07`, `0x08`, `0x0f`, `0x10`
- bitmap decode helpers
- report parser for the `0x21` family
- app-level synthesis of `key_completed`

## Non-calibration families confirmed during this pass

These families are real, but not part of the calibration start flow:

- `0x01`
  - heartbeat and device capability/status
- `0x21 / 0x05`
  - trigger-table reads
- `0x21 / 0x09`
  - poll-rate read or write
- `0x25`
  - switch tables
- `0x26`
  - deadband tables

## Open items

1. `0x03` pre-flight command
   - present in HID capture
   - still missing a JavaScript call site

2. Direct UI call site for `reviseKey()`
   - the function exists in `agreement.min.js`
   - the exact binding path from the current downloaded UI was not found yet
   - the payload is still reliable because the function itself is present and explicit

3. Terminal distinction between manual cancel and device success
   - vendor UI uses a local `isChangeCalibration` flag to choose the final alert
   - that means Flutter should track local cancel intent instead of expecting a dedicated cancel opcode from the device
