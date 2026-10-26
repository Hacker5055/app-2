# Signal model

Everything the radar shows is derived from one number per packet: RSSI, in dBm.
This document explains how that number becomes “0.8 meters away”, and where the
model lies to you.

## 1. From RSSI to distance

Free-space and indoor radio propagation are approximated by the log-distance
path-loss model:

```text
RSSI(d) = TxPower − 10 · n · log10(d)

        = 10 ^ ((TxPower − RSSI) / (10 · n))
```

* **TxPower** (a.k.a. RSSI@1m) is the strength you would measure at exactly one
  metre. Default **−59 dBm**.
* **n** is the path-loss exponent: 2.0 in free space, **2.5** in a typical room,
  3.0–3.5 through walls and furniture.
* The inverse is solved in `PathLossCalculator.distanceMeters`.

Worked examples with the defaults:

| RSSI | (TxPower − RSSI) / (10n) | distance |
| ---- | ------------------------- | -------- |
| −34 dBm | −1.0 | 0.10 m |
| −59 dBm | 0.0 | 1.00 m |
| −69 dBm | 0.4 | 2.51 m |
| −84 dBm | 1.0 | 10.0 m |
| −109 dBm | 2.0 | 100 m |

Guard rails:

* RSSI is clamped to `[-127, -20]` dBm — below the sensitivity floor and above
  physically plausible values.
* Distance is clamped to `[0.05, 200]` m so the radar scale can never divide by zero
  or draw a node outside its rings.

## 2. Why the raw value is unusable

A single packet's RSSI swings by ±10 dB simply because a hand, a body or a doorway
crossed the path. At `n = 2.5`, 10 dB is a factor of 2.5 in distance — a node would
jump from 1 m to 2.5 m and back, several times per second.

So every device gets its own exponential moving average:

```text
s[0] = x[0]
s[i] = α · x[i] + (1 − α) · s[i−1]      α = 0.35
```

Properties with α = 0.35:

* one 20 dB spike moves the estimate by `0.35 × 20 = 7 dB`,
* after 5 packets ~88 % of a step change is absorbed,
* the effective time constant is ~2.3 packets (≈ 1–2 s at typical advertising
  intervals).

Distance, zone, bars and Geiger cadence are all computed from `s[i]`, never from `x[i]`.
The UI publishes a snapshot every 1000 ms (`AppConstants.uiRefreshInterval`).

## 3. Zones

| Zone | Range | Colour | Ping | Haptic |
| ---- | ----- | ------ | ---- | ------ |
| hot | `< 1 m` | `#FF3355` neon red | 130 ms | 320 ms |
| warm | `1 – 3 m` | `#FF8A1F` electric orange | 380 ms | 620 ms |
| moderate | `3 – 10 m` | `#B14BFF` vibrant purple | 800 ms | 1100 ms |
| cold | `> 10 m` | `#00E5FF` deep cyan | 1600 ms | 1600 ms |

Boundaries are inclusive at the lower edge (`exactly 1.0 m` is warm, `exactly 3.0 m`
is moderate, `exactly 10.0 m` is cold). Non-finite or negative distances collapse to
`hot` — a broken reading must never look like “far away”.

## 4. Geiger feedback

`ProximityPulse` interpolates continuously instead of switching between four
intervals:

```text
u      = clamp(|d| / range, 0, 1)
eased  = u ^ 0.65
ping   = 130 ms + (1600 − 130) × eased
haptic = 1.45 × ping
volume = 0.18 + 0.55 × (1 − u)²
```

The `0.65` exponent makes the cadence accelerate noticeably in the last metre
(≈ 130 ms at 0 m, ≈ 340 ms at 1 m, ≈ 810 ms at 10 m), which is what actually helps
you home in. Audio is disabled in silent mode by the OS volume; haptics are skipped
when the user turns them off in Settings.

## 5. Direction: the 360° sweep assistant

BLE advertisements carry no bearing. The phone has a magnetometer, so direction is
recovered by rotating the phone and watching which way the signal peaks:

1. Sample `(compassHeading, latestSmoothedRssi)` at up to 20 Hz while the user turns.
2. Normalise RSSI to weights `w = 0.05 + 0.95 · ((rssi − min) / (max − min))²`.
3. Sum unit vectors `Σ w·(cos θ, sin θ)` and take `atan2` — a **circular** mean, so
   the 0°/360° seam does not flip the result to the opposite side.
4. `confidence = |Σ vector| / Σ w` (0 = uniform, 1 = strongly directional).
5. Display the fused heading, the single strongest sample, and the 8-point compass
   label; allow **Lock** to store the bearing on the device snapshot.

Until a sweep is locked, nodes are parked on a deterministic FNV-1a hash of the
device id scaled to the circle (`StableAngle.radiansFromId`) so they do not teleport
between rebuilds.

## 6. Calibration

Settings exposes TxPower (−90 … −35 dBm) and `n` (1.5 … 4.5). The practical recipe:

1. Stand exactly one metre from the device; tap **Calibrate at 1 m** to adopt the
   current smoothed RSSI as TxPower.
2. If the estimate grows too slowly as you walk away, raise `n`; if it over-reacts,
   lower it.

Per-device calibration is stored on `BleDevice.txPowerUsed` /
`pathLossExponentUsed` so the UI can show what was used for that reading.

## 7. Known limitations

* **Multipath.** Reflections create local maxima: the ping can briefly speed up while
  you walk past a doorway. EMA dampens but cannot remove this.
* **Orientation.** Phone and device antennas are directional; rotating either changes
  RSSI by several dB even at constant distance.
* **Bodies.** A human between phone and tag attenuates 10–20 dB — that is why the hot
  zone feels “sticky” when you are close but facing away.
* **Non-linear devices.** Some trackers advertise infrequently (1–2 s), so their
  distance updates lag; the 10 s watchdog and 18 s stale timeout account for this.
* **No trilateration.** With one antenna you get range, not bearing, without the
  manual sweep. The sweep assistant is a direction finder, not AoA hardware.

Use the radar as a homing aid: it tells you whether you are getting warmer, and the
sweep tells you which way to turn. It cannot tell you that the keys are under the
third cushion.
