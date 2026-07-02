# SafeRide Algorithm Implementation Validation

## Mathematical Model vs Implementation Alignment

### ✅ Core Components Implemented

#### 1. **Sensor Data Preprocessing**
- **Formula:** `a(k) = √(ax(k)² + ay(k)² + az(k)²)`
- **Location:** `risk_scoring.dart` - `computeAccelerationMagnitude()`
- **Status:** ✅ IMPLEMENTED
- **Usage in TripController:** `_onUserAccelerometer()` - calculates magnitude

- **Formula:** `g(k) = √(gx(k)² + gy(k)² + gz(k)²)`
- **Location:** `risk_scoring.dart` - `computeGyroMagnitude()`
- **Status:** ✅ IMPLEMENTED (ready for use)
- **Current Usage:** TripController uses only Z-axis (`event.z.abs()`) - **NEEDS ALIGNMENT**

#### 2. **Moving Average Filter**
- **Formula:** `x̃(k) = (1/M) * Σ(x(k-i))` for i=0 to M-1
- **Location:** `risk_scoring.dart` - `movingAverageFilter()`
- **Status:** ✅ IMPLEMENTED
- **Usage:** Available for preprocessing acceleration data

#### 3. **Adaptive Thresholds**
- **Formula:** `θ(t) = θ₀ * C_r(t) * C_v(t) * C_t(t)`
- **Location:** `risk_scoring.dart` - `AdaptiveThresholds` class
- **Status:** ✅ FULLY IMPLEMENTED
- **Current Usage:** Not actively used in TripController - **NEEDS ALIGNMENT**
- **Base Thresholds:**
  - `thetaSpeedingBase = 40.0` (m/s or km/h)
  - `thetaBrakingBase = -8.0` (m/s²)
  - `thetaTurningBase = 1.5` (rad/s)

#### 4. **Pothole Detection**
- **Formula:** `P(k) = 1 if az(k) > θ_p ∧ g(k) < θ_g ∧ v(k) > θ_v`
- **Location:** `risk_scoring.dart` - `detectPothole()`
- **Status:** ✅ IMPLEMENTED
- **Current Usage:** Not used in TripController - **NEEDS INTEGRATION**

#### 5. **Event Detection**
- **Overspeeding:** `E_v(w) = 1 if v_w > θ_v`
  - Location: `risk_scoring.dart` - `detectOverspeeding()`
  - Status: ✅ IMPLEMENTED
  - TripController: Uses hardcoded threshold (20 m/s) - **SHOULD USE ADAPTIVE**

- **Harsh Braking:** `E_b(w) = 1 if Δv(k) < -θ_b`
  - Location: `risk_scoring.dart` - `detectHarshBraking()`
  - Status: ✅ IMPLEMENTED
  - TripController: Uses acceleration magnitude instead of speed variation - **NEEDS CORRECTION**
  - Current: `_accelWindow.max > 3.5`
  - Should use: Speed variation from GPS data

- **Sharp Turning:** `E_g(w) = 1 if g_w_max > θ_g`
  - Location: `risk_scoring.dart` - `detectSharpTurning()`
  - Status: ✅ IMPLEMENTED
  - TripController: Uses only Z-axis - **SHOULD USE FULL GYRO MAGNITUDE**
  - Current: `event.z.abs() > 2.5`
  - Should use: `computeGyroMagnitude(gx, gy, gz) > threshold`

#### 6. **Sensor-Based Risk Score**
- **Formula:** `R_sens(t) = (w1*C_v + w2*C_b + w3*C_g + w4*P(t) + w5*|S(t)|) / W_total`
- **Location:** `risk_scoring.dart` - `computeSensorRiskScore()`
- **Status:** ✅ FULLY IMPLEMENTED
- **Weights:** Normalized to sum = 1
  - w1 = 0.25 (Overspeeding)
  - w2 = 0.30 (Harsh Braking)
  - w3 = 0.20 (Sharp Turning)
  - w4 = 0.15 (Pothole)
  - w5 = 0.10 (Slope)

#### 7. **Report-Based Risk Score**
- **Formula:** `R_rep(t) = Σ(T_i(t) * r_i(t)) / Σ(T_i(t))`
- **Location:** `risk_scoring.dart` - `computeReportRiskScore()`
- **Status:** ✅ FULLY IMPLEMENTED
- **Integration:** Ready for passenger reports from report_screen.dart

#### 8. **Adaptive Weight Function**
- **Formula:** `λ(t) = N_sensor(t) / (N_sensor(t) + N_report(t))`
- **Location:** `risk_scoring.dart` - `computeAdaptiveWeight()`
- **Status:** ✅ FULLY IMPLEMENTED

#### 9. **Nonlinear Risk Fusion**
- **Formula:** `R_trip(t) = λ(t)*R_sens(t) + (1-λ(t))*R_rep(t) + φ*|R_sens(t) - R_rep(t)|`
- **Location:** `risk_scoring.dart` - `computeTripRiskScore()`
- **Status:** ✅ FULLY IMPLEMENTED
- **Inconsistency Penalty (φ):** 0.15

#### 10. **Safety Score**
- **Formula:** `S_trip(t) = 100 * (1 - R_trip(t))`
- **Location:** `risk_scoring.dart` - `computeSafetyScore()`
- **Status:** ✅ FULLY IMPLEMENTED
- **Output Range:** 0-100 (higher = safer)

---

## Implementation Alignment Issues & Solutions

### ⚠️ ISSUE 1: Gyroscope Full Magnitude Not Used
**Current:** `event.z.abs()` (only Z-axis)
**Should Be:** `computeGyroMagnitude(event.x, event.y, event.z)` (full 3D magnitude)
**Impact:** Incomplete turning detection; missing rotations on X and Y axes
**Fix Location:** `trip_controller.dart` - `_onGyroscope()` method

### ⚠️ ISSUE 2: Braking Detection Using Wrong Metric
**Current:** Uses acceleration magnitude from sliding window
**Should Be:** Speed variation from GPS (Δv(k) = ṽ(k) - ṽ(k-1))
**Impact:** Incorrect harsh braking events; mixing different sensor types
**Fix Location:** `trip_controller.dart` - needs to track speed deltas instead

### ⚠️ ISSUE 3: Adaptive Thresholds Not Used
**Current:** Hardcoded thresholds in trip_controller
**Should Be:** Use `AdaptiveThresholds` with context factors
**Example:**
- Speeding: Should use `thresholds.speedingThreshold` (40 m/s * context factors)
- Turning: Should use `thresholds.turningThreshold` (1.5 rad/s * context factors)
- Braking: Should use `thresholds.brakingThreshold` (-8 m/s² * context factors)
**Impact:** Loss of contextual awareness; missing road/traffic condition adaptation
**Fix Location:** `trip_controller.dart` - initialize and use AdaptiveThresholds

### ⚠️ ISSUE 4: Pothole Detection Not Integrated
**Current:** Implemented in risk_scoring.dart but not used in TripController
**Should Be:** Called during sensor processing to detect road hazards
**Requirements:** Needs altitude data from GPS (for slope calculation)
**Fix Location:** Add to `_onPosition()` and `_onUserAccelerometer()` coordinated check

### ⚠️ ISSUE 5: Slope Calculation Missing
**Formula:** `S(t) = (h(t) - h(t-1)) / d(t)`
**Current:** Not implemented in trip_controller
**Should Be:** Calculate elevation change per distance traveled
**Data Required:** GPS altitude and distance between readings
**Fix Location:** `trip_controller.dart` - track altitude and compute slopes

---

## Classes Alignment Summary

### ✅ Properly Aligned Classes
1. `SensorReading` - Captures all 9 sensor axes + GPS data
2. `AdaptiveThresholds` - Implements adaptive threshold formula
3. `RiskWeights` - Normalizes weights to sum=1
4. `WindowMetrics` - Aggregates window-based statistics
5. `SlidingWindow` - Implements moving window analysis
6. `UnsafeEvent` & `UnsafeEventType` - Event tracking

### ⚠️ Classes Needing Better Integration
1. `PassengerReport` - Defined but needs active use from reports
2. `AdaptiveThresholds` - Defined but not actively used in TripController
3. `WindowMetrics` - Defined but not extracted from data streams

---

## Data Flow Verification

### Current Data Flow
```
GPS Stream (_onPosition)
  ↓
Speed tracking & storage
  ↓
Speeding count++ (if speed > 20)

Accelerometer Stream (_onUserAccelerometer)
  ↓
Magnitude calculation ✅
  ↓
Sliding window storage ✅
  ↓
Braking count++ (if accel > 3.5)  ⚠️ WRONG METRIC

Gyroscope Stream (_onGyroscope)
  ↓
Z-axis only ⚠️ INCOMPLETE
  ↓
Turning count++ (if z > 2.5)

Stop Trip
  ↓
computeRiskScore(speedingCount, brakingCount, turningCount, reportSeverity)
  ↓
Output: Risk Score (0+)  ⚠️ NOT 0-1 NORMALIZED
```

### Required Data Flow (Per Algorithm)
```
GPS Stream → Extract: v(k), h(k), d(k)
Accelerometer Stream → Extract: ax(k), ay(k), az(k)
Gyroscope Stream → Extract: gx(k), gy(k), gz(k)
  ↓
Magnitude: a(k), g(k)
  ↓
Filtering: ã(k), g̃(k)
  ↓
Sliding Windows → Extract v_w, g_w_max, Δv
  ↓
Event Detection:
  - E_v: v_w > θ_v
  - E_b: Δv < -θ_b
  - E_g: g_w_max > θ_g
  - P: Pothole detection
  ↓
Aggregation: C_v, C_b, C_g, P, S
  ↓
R_sens = (w1*C_v + w2*C_b + w3*C_g + w4*P + w5*|S|) / W_total
  ↓
R_rep = weighted passenger reports (if available)
  ↓
λ = adaptive weight
  ↓
R_trip = λ*R_sens + (1-λ)*R_rep + φ*|R_sens - R_rep|
  ↓
S_trip = 100 * (1 - R_trip)
  ↓
Output: Safety Score (0-100)
```

---

## Recommendations

1. **HIGH PRIORITY:** Fix gyroscope processing to use full magnitude
2. **HIGH PRIORITY:** Correct braking detection to use GPS speed variation
3. **MEDIUM PRIORITY:** Integrate AdaptiveThresholds into TripController
4. **MEDIUM PRIORITY:** Implement pothole detection with altitude data
5. **MEDIUM PRIORITY:** Implement slope calculation from GPS
6. **LOW PRIORITY:** Optimize window size and sliding window parameters
7. **TESTING:** Validate final safety score matches mathematical formula

---

## Testing Checklist

- [ ] Verify R_sens(t) is between 0-1
- [ ] Verify R_rep(t) is between 0-1
- [ ] Verify λ(t) is between 0-1
- [ ] Verify R_trip(t) is between 0-1
- [ ] Verify S_trip(t) is between 0-100
- [ ] Verify adaptive thresholds adjust with context
- [ ] Verify gyro full magnitude is used
- [ ] Verify braking uses speed variation, not acceleration
- [ ] Verify pothole detection works when integrated
- [ ] Verify slope calculation from GPS altitude

