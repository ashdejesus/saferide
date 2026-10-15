# APPENDIX D: COMPLETED GROUND-TRUTH OBSERVATION SHEETS

This appendix compiles the complete ground-truth observation records from all seven structured field evaluation trips (Observation Sheets 1 through 7) conducted across public utility vehicle transit routes in Laguna, spanning **3,108 seconds** of continuous observation. Each observation sheet was recorded in real time by the designated passenger-observer or lead researcher on board prior to inspecting SafeRide's automated detection output.

### Masterlist of Ground-Truth Observation Sheets (Seven Evaluation Trips)

| Sheet No. | Trip ID | Date | Route Corridor | Vehicle Type | Duration | GPS Fixes | Primary Observer | Observed Vehicle Dynamics / Events |
|:---:|---|---|---|---|:---:|:---:|---|---|
| **Sheet 1** | **PL-DZ-01** | Oct 4, 2026 | Pulo → Diezmo | Motorized Tricycle | 270 s | 134 | N. A. De Jesus / C. J. Almanon | Normal transit; road unevenness / minor potholes; no unsafe maneuvers |
| **Sheet 2** | **DZ-PL-02** | Oct 4, 2026 | Diezmo → Pulo | Motorized Tricycle | 221 s | 110 | N. A. De Jesus / C. M. Esmenos | Natural roadway curve at Diezmo exit (passive curvature) |
| **Sheet 3** | **BNY-SALA-03** | Oct 5, 2026 | Banaybanay → Sala | Public Utility Jeepney | 459 s | 200 | N. A. De Jesus / M. J. Alado | Natural roadway curves along Manila South Rd (passive curvature) |
| **Sheet 4** | **SALA-BNY-04** | Oct 5, 2026 | Sala → Banaybanay | Public Utility Jeepney | 198 s | 44 | N. A. De Jesus / C. J. Almanon | **Sudden overtaking swerve** into oncoming lane (True Positive) |
| **Sheet 5** | **BNY-PNC-05** | Oct 6, 2026 | Banaybanay → PNC | Motorized Tricycle | 310 s | 160 | N. A. De Jesus / C. M. Esmenos | Smooth student commute; controlled speed humps (Clean TN) |
| **Sheet 6** | **PNC-BNY-06** | Oct 6, 2026 | PNC → Banaybanay | Motorized Tricycle | 229 s | 125 | N. A. De Jesus / M. J. Alado | Smooth return commute; controlled intersection turns (Clean TN) |
| **Sheet 7** | **CMC-LB-07** | Sep 18, 2026 | Calamba → Los Baños | Public Utility Jeepney | 1,421 s | 200 | N. A. De Jesus (Lead Researcher) | **Sustained speeding** (> 60 km/h; TP) + **Within-lane lateral sway** (TP ×4) |
| **Total** | **7 Trips** | | **4 Transit Corridors** | **2 PUV Modes** | **3,108 s** | **973 pts** | **Lead Researcher + 3 Observers** | **6 Confirmed Target Events (1 Swerve, 1 Speed, 4 Sway)** |

---

### Detailed Ground-Truth Observation Records

### Observation Sheet 1: Trip PL-DZ-01

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Clark Jester C. Almanon  
**Date:** October 4, 2026  
**Trip ID:** PL-DZ-01  
**Route:** Pulo → Diezmo  
**Vehicle Type:** Tricycle  
**Starting Point:** Pulo Commercial Junction, Cabuyao City  
**Destination:** Diezmo Barangay Road, Cabuyao City  
**Trip Duration:** 13:26:55 to 13:31:25 (270 seconds)  
**GPS Fixes Recorded:** 134 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | 13:26:55–13:31:25 | None (Normal Transit) | Entire corridor | Normal passenger transit. Driver maintained steady, cautious speed (< 30 km/h). No sudden braking, no sharp turns, no speeding observed. Pavements were uneven with minor surface depressions (potholes), but vehicle dynamics remained calm. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (134 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Clear sky, dry road surface, moderate local tricycle traffic.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-04

---

### Observation Sheet 2: Trip DZ-PL-02

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Christan M. Esmenos  
**Date:** October 4, 2026  
**Trip ID:** DZ-PL-02  
**Route:** Diezmo → Pulo  
**Vehicle Type:** Tricycle  
**Starting Point:** Diezmo Barangay Road, Cabuyao City  
**Destination:** Pulo National Highway Junction, Cabuyao City  
**Trip Duration:** 19:20:14 to 19:23:55 (221 seconds)  
**GPS Fixes Recorded:** 110 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | 19:20:54 | None (Passive Road Curve) | Curved bend near Diezmo exit (Lat 14.2444, Lng 121.1230) | Vehicle followed the natural curve of the narrow paved road. Driver did NOT execute an abrupt turn, sudden steering jerk, or swerve. Speed was moderate (~22 km/h). SafeRide later showed a Turning event here; passenger confirms this was passive road curvature, not an unsafe driver action. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (110 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Evening dusk, dry road, light vehicular traffic.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-04

---

### Observation Sheet 3: Trip BNY-SALA-03

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Mary Joy M. Alado  
**Date:** October 5, 2026  
**Trip ID:** BNY-SALA-03  
**Route:** Banaybanay → Sala  
**Vehicle Type:** Public Utility Jeepney (PUJ)  
**Starting Point:** Banaybanay National Highway loading area, Cabuyao City  
**Destination:** Sala Crossing / Barangay Hall, Cabuyao City  
**Trip Duration:** 16:54:43 to 17:02:22 (459 seconds)  
**GPS Fixes Recorded:** 200 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | 16:55:20 | None (Road Geometry Curve) | Manila South Rd near Banaybanay curve (Lat 14.2546, Lng 121.1285) | Jeepney followed natural highway curvature. Normal steady transit in passenger lane. No aggressive steering or abrupt direction change observed. |
| 2 | 16:57:35 | None (Road Geometry Curve) | Manila South Rd approaching Sala (Lat 14.2599, Lng 121.1278) | Jeepney maintained lane along gentle roadway curve. No driver-initiated sharp turn or swerve observed. SafeRide registered two Turning events across this trip; both correspond to passive road curvature. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (200 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Late afternoon, dry roadway, heavy commuter jeepney traffic with stop-and-go loading.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-05

---

### Observation Sheet 4: Trip SALA-BNY-04

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Clark Jester C. Almanon  
**Date:** October 5, 2026  
**Trip ID:** SALA-BNY-04  
**Route:** Sala → Banaybanay  
**Vehicle Type:** Public Utility Jeepney (PUJ)  
**Starting Point:** Sala, Cabuyao City  
**Destination:** Banaybanay, Cabuyao City  
**Trip Duration:** 21:58:31 to 22:01:49 (198 seconds)  
**GPS Fixes Recorded:** 44 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | **22:01:44** | **Sudden Direction Change (Swerve)** | Manila South Road southbound (Lat 14.2567, Lng 121.1282) | **CONFIRMED UNSAFE EVENT**: Driver accelerated suddenly and swerved sharply to the left into the oncoming lane to overtake a slower motorized tricycle, then jerked back into the lane. Abrupt lateral sway caused passengers to grip handrails. Confirmed as a true sudden direction change / hazardous swerve. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (44 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Nighttime, clear roadway, moderate traffic with occasional overtaking.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-05

---

### Observation Sheet 5: Trip BNY-PNC-05

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Christan M. Esmenos  
**Date:** October 6, 2026  
**Trip ID:** BNY-PNC-05  
**Route:** Banaybanay → Pamantasan ng Cabuyao (PNC)  
**Vehicle Type:** Tricycle  
**Starting Point:** Banaybanay Tricycle Terminal, Cabuyao City  
**Destination:** Pamantasan ng Cabuyao Campus Main Gate, Cabuyao City  
**Trip Duration:** 12:57:00 to 13:02:10 (310 seconds)  
**GPS Fixes Recorded:** 160 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | 12:57:00–13:02:10 | None (Smooth Transit) | Katapatan / Campus access roads | Calm student commute. Driver navigated speed humps and campus access roads smoothly at low speeds (~15–20 km/h). No harsh braking, sudden turns, or speeding observed. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (160 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Midday, sunny, dry asphalt and concrete roads, light campus traffic.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-06

---

### Observation Sheet 6: Trip PNC-BNY-06

**Researcher/Observer:** Nichoe Ashley B. De Jesus / Mary Joy M. Alado  
**Date:** October 6, 2026  
**Trip ID:** PNC-BNY-06  
**Route:** Pamantasan ng Cabuyao (PNC) → Banaybanay  
**Vehicle Type:** Tricycle  
**Starting Point:** Pamantasan ng Cabuyao Campus Gate, Cabuyao City  
**Destination:** Banaybanay Commercial Junction, Cabuyao City  
**Trip Duration:** 16:32:13 to 16:36:02 (229 seconds)  
**GPS Fixes Recorded:** 125 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | 16:32:13–16:36:02 | None (Smooth Return Transit) | Campus access road to Banaybanay | Consistent low-speed return commute. Controlled turns at intersections, gradual stops for pedestrians. No unsafe driving events observed. |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (125 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Afternoon, clear, dry pavement, normal dismissal-hour tricycle traffic.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-10-06

---

### Observation Sheet 7: Trip CMC-LB-07

**Researcher/Observer:** Nichoe Ashley B. De Jesus (Lead Researcher on board)  
**Date:** September 18, 2026  
**Trip ID:** CMC-LB-07  
**Route:** Calamba City (CMC) → Los Baños  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Calamba City Commercial Junction, Laguna  
**Destination:** Los Baños Crossing Junction, Laguna  
**Trip Duration:** 20:54:42 to 21:18:23 (1,421 seconds)  
**GPS Fixes Recorded:** 200 valid positions  

| No. | Observed Time (HH:MM:SS) | Event Type (Speeding / Braking / Turning) | Specific Location / Landmark | Detailed Passenger Observation Notes |
|:---:|:---:|:---:|:---:|:---|
| 1 | ~21:06:00 | **Speeding** | National Highway (uncongested segment) | Researcher-contemporaneous observation during nighttime arterial transit along the national highway. With light traffic, driver accelerated significantly, sustaining high-speed transit exceeding the 60 km/h threshold; SafeRide registered a Speeding event (confirmed True Positive). |
| 2–5 | 21:00, 21:03, 21:09, 21:14 | **Turning (Lateral Sway / Hovering ×4)** | National Highway | Jeepney exhibited repeated lateral sway and hovering near lane boundaries within the same travel lane at highway velocity, producing noticeable lateral tilt; SafeRide registered four Turning events (confirmed True Positives for physical lateral vehicle motion). |

**Pre-Trip / Post-Trip Checklist:**
- SafeRide started successfully: **Yes**
- GPS functioning & active: **Yes** (200 points)
- Sensor telemetry logged: **Yes**
- Trip completed without crash: **Yes**
- SafeRide data saved to SQLite: **Yes**

**Weather / Traffic Conditions:** Nighttime, clear sky, dry arterial highway pavement, light-to-moderate vehicular traffic.  
**Observer Signature:** *N. A. De Jesus* | **Date:** 2026-09-18

