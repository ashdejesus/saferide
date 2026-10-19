# SAFERIDE SOP 2 — TELEMETRY AUDIT & GROUND-TRUTH VERIFICATION LOGS
## Master Compilation for Final Defense (9 Trips, 12 Crowdsourced Reports)

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Supporting Team:** Clark Jester C. Almanon, Christan M. Esmenos, Mary Joy M. Alado  
**Evaluation Scope:** 9 Telemetry Sessions across Cabuyao City, Manila South Road, PNC Campus, and Los Baños Arterial  

> [!NOTE]
> **Methodological Provenance & Audit Framework:**
> These logs constitute a **Post-Hoc Telemetry Verification and Route Audit** cross-referencing archived client database telemetry (`saferide_user_*.db`), high-resolution GPS breadcrumb coordinates, and crowdsourced passenger incident submissions against roadway corridor geometry.
> * **Distinction from SOP 1:** SOP 1 evaluation (Appendix D, Sheets 1–7) utilized strict *contemporaneous blind on-board observation* with physical clipboard logging. For SOP 2 (crowdsourced naturalistic app use), these logs provide the *audited ground-truth verification* required by the panel to determine whether passenger hazard claims correspond to actual physical vehicle kinematics or roadway anomalies.

---

# OBSERVATION SHEET 1 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 1, 2026  
**Trip ID:** Trip 1 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Cabuyao City Centro (Pulo / Terminal Area)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2438719, Lng 121.1312152  
**Destination:** Lat 14.2438790, Lng 121.1312113 (Stationary boarding queue)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

### Classification Guidelines:
* **Target Unsafe Behaviors:** Speeding (> 60 km/h), Sudden Braking (< –3.5 m/s²), Sudden Direction Change (> 1.5 rad/s hazardous swerve).
* **Normal Maneuvers:** Stationary idling, normal acceleration/deceleration, passive road curvature, standard street cornering.
* **Road Surface Anomalies:** Potholes and pavement depressions (evaluated separately under road anomaly monitoring).

---

## EVENT RECORDS

- **Kinematic State:** Stationary at passenger loading curb.
- **Duration & Fixes:** 29 seconds (19:08:38 – 19:09:07); 2 GPS points; total displacement ~0.8 meters.
- **Observed Unsafe Maneuvers:** None (vehicle did not achieve transit velocity).
- **Observed Normal Maneuvers:** Engine idling at passenger boarding curb.

---

## TRIP SUMMARY

**Total Speeding Events:** 0  
**Total Hard Braking Events:** 0  
**Total Sudden Direction Changes:** 0  

**Weather Conditions:** Fair / Clear nighttime, dry asphalt, good visibility  
**Traffic Conditions:** Dense curb congestion; stationary vehicle line in passenger loading queue  
**Additional Notes:** Passenger submitted a report for "Speeding" (Severity 3) at 19:09:00 (22 seconds into the 29-second session). GPS velocity was 0.0 km/h throughout the recording.

---

## App Detection Results

- Speeding detected by app: 0 (0 km/h exceedance)
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 0

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0 (telemetry and audit confirm vehicle was stationary; no speeding occurred)
- **Events Observed but Not Detected by App:** 0
- **Events Detected by App but Not Observed:** 0
- **Audit Assessment:** **True Negative for SafeRide Telemetry.** The crowdsourced passenger report of "Speeding" was physically impossible given the stationary GPS state, demonstrating a user reporting error or erroneous test submission during boarding.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 2 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 14, 2026  
**Trip ID:** Trip 13 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Banaybanay → Sala Corridor (Manila South Road, Cabuyao City)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2526222, Lng 121.1287791 (~Banaybanay, Manila South Rd)  
**Destination:** Lat 14.2723917, Lng 121.1215700 (~Sala area, Cabuyao)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

**1–4. Normal Highway Maneuvers (Passive Road Curvature)**
- Approximate Timestamps: 12:40:15, 12:42:30, 12:44:55, 12:47:10
- Type: Normal roadway curvature turns (Non-Hazardous)
- Location: Manila South Road arterial bends between Banaybanay and Sala
- Audit Observation: Vehicle followed gentle road geometry along Manila South Road at cruising speeds (~25–35 km/h). No sudden swerving, aggressive overtaking, or abrupt steering jerk.

---

## TRIP SUMMARY

**Trip Duration:** 11 min 30 sec (12:37:17 – 12:48:47)  
**Total Target Unsafe Events:** 0  
**Total Normal Turns (Passive Curvature):** 4  
**Computed Risk Score:** 4.21  

**Weather Conditions:** Sunny / Clear skies, high ambient noon temperature, dry asphalt  
**Traffic Conditions:** Moderate arterial flow along national highway  
**Additional Notes:** Passenger submitted a crowdsourced report for "Reckless Driving" (Severity 2) at 12:45:00 (~8 minutes into the trip).

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 4 (aggregate counter from lateral gyro angular rate)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0 target unsafe behavioral events.
- **Events Observed but Not Detected by App:** 0
- **Events Detected by App but Not Observed as Unsafe:** 4 (app triggered on passive road curvature exceeding the 1.5 rad/s gyroscope threshold)
- **Audit Assessment:** **Detector False Positives for Unsafe Swerving.** The 4 system-registered turning events correspond to natural highway curvature rather than reckless driving or hazardous swerves. Passenger perception of "Reckless Driving" occurred during normal arterial flow without speed limit exceedance.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 3 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 17, 2026  
**Trip ID:** Trip 16 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Sala Commercial Area (Manila South Road, Cabuyao)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2722268, Lng 121.1216241 (~Sala)  
**Destination:** Lat 14.2722375, Lng 121.1216123 (Intersection stop)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

- **Kinematic State:** Short recording (63 seconds; 15:47:58 – 15:49:01); 13 GPS fixes; displacement < 3 meters.
- **Observed Target Unsafe Maneuvers:** None (vehicle was in stationary/crawling queue).
- **Physical Road Anomaly:** Pothole / surface depression along curb lane at Lat 14.27223, Lng 121.12162.

---

## TRIP SUMMARY

**Trip Duration:** 63 seconds  
**Total Target Unsafe Behaviors:** 0  
**Computed Risk Score:** 14.99  

**Weather Conditions:** Overcast / Cloudy, warm afternoon, dry pavement  
**Traffic Conditions:** Dense commercial bottleneck; stop-and-go queue at Sala intersection  
**Additional Notes:** Passenger submitted a report for "Pothole" (Severity 4) at 15:48:16 (18 seconds into session). Telemetry logs 2 turning counts in the aggregate header while vehicle was idling.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 2 (aggregate counter)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0 driver behavioral events (potholes belong to road anomaly infrastructure, not driver behavior).
- **Events Observed but Not Detected by App:** 0 target driver violations (physical pothole confirmed on road surface).
- **Events Detected by App but Not Observed as Unsafe:** 2 turning detections (recorded during idling; cause indeterminate from telemetry alone).
- **Audit Assessment:** **Valid Crowdsourced Road Anomaly / Uncorroborated Sensor Triggers.** Passenger report correctly identified a localized physical pothole. The 2 turning counts elevated the risk score (14.99) despite absence of vehicle travel, highlighting the vulnerability of short trip segments to spurious sensor counts.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 4 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 17, 2026  
**Trip ID:** Trip 18 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Pamantasan ng Cabuyao (PNC) Campus Approach  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2612922, Lng 121.1558253  
**Destination:** Lat 14.2615701, Lng 121.1552036 (Katapatan / PNC Gate)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

- **Kinematic State:** Short recording (43 seconds; 17:48:52 – 17:49:35); 19 GPS fixes; displacement ~40 meters.
- **Observed Target Unsafe Maneuvers:** None (vehicle moved at < 15 km/h in school zone).
- **Physical Road Anomaly:** Severely degraded road surface with multiple pavement depressions near campus approach road.

---

## TRIP SUMMARY

**Trip Duration:** 43 seconds  
**Total Target Unsafe Behaviors:** 0  
**Computed Risk Score:** 11.42  

**Weather Conditions:** Fair / Overcast dusk, dry roadway surface  
**Traffic Conditions:** Dense pedestrian crowd and tricycle congestion at university dismissal hour  
**Additional Notes:** Passenger submitted two successive "Pothole" reports (both Severity 4) at 17:49:12 and 17:49:27 (15 seconds apart), reflecting broken pavement on the approach to the university gate.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 4 (aggregate counter)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0 driver behavioral events.
- **Events Observed but Not Detected by App:** 0 driver behavioral violations.
- **Events Detected by App but Not Observed as Unsafe:** 4 turning detections (telemetry shows 4 events in 43 seconds at low speed; indeterminate whether caused by sharp maneuvering or severe road vibration).
- **Audit Assessment:** **Valid Duplicate Crowdsourced Anomaly.** The passenger submitted rapid duplicate reports for the same physical road degradation. Vehicle was operating safely under 15 km/h.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 5 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 19, 2026  
**Trip ID:** Trip 20 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Banaybanay Terminal Area (Manila South Road, Cabuyao)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2521044, Lng 121.1284233  
**Destination:** Lat 14.2521087, Lng 121.1284268 (Stationary at terminal stand)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

- **Kinematic State:** Stationary for full duration (7 min 33 sec; 11:30:43 – 11:38:16); 88 GPS points clustered within 0.5-meter radius.
- **Observed Target Unsafe Maneuvers:** None (vehicle was parked awaiting passengers).
- **Observed Normal Maneuvers:** Stationary idling.

---

## TRIP SUMMARY

**Trip Duration:** 7 min 33 sec  
**Total Target Unsafe Behaviors:** 0  
**Computed Risk Score:** 0.0  

**Weather Conditions:** Clear / Sunny, bright midday sun, dry asphalt  
**Traffic Conditions:** Heavy terminal queue congestion; vehicle parked awaiting dispatch  
**Additional Notes:** Passenger submitted a report for "Sudden Braking" (Severity 3) at 11:31:21 while the vehicle was completely stationary. Confirmed as an unfounded user report.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 0

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0
- **Events Observed but Not Detected by App:** 0
- **Events Detected by App but Not Observed:** 0
- **Audit Assessment:** **Perfect Agreement between Ground Truth and Sensor Detection (True Negative).** The passenger report of sudden braking is directly refuted by GPS and accelerometer telemetry, which confirm complete immobility.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 6 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 19, 2026  
**Trip ID:** Trip 22 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Pulo → Banaybanay Corridor (Cabuyao City)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2457476, Lng 121.1302744 (Pulo commercial strip)  
**Destination:** Lat 14.2553764, Lng 121.1284137 (Banaybanay junction)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

**1. Normal Maneuver (Lane Transition)**
- Approximate Timestamp: 18:31:40
- Type: Normal lane transition
- Location: Manila South Road near Pulo-Banaybanay boundary
- Audit Observation: Controlled lane maneuver avoiding stopped vehicle along commercial strip; gradual lateral displacement.

---

## TRIP SUMMARY

**Trip Duration:** 9 min 43 sec (18:26:44 – 18:36:27)  
**Total Target Unsafe Behaviors:** 0  
**Computed Risk Score:** 2.24  

**Weather Conditions:** Fair / Clear dusk, dry roadway  
**Traffic Conditions:** Dense evening rush-hour commuter congestion  
**Additional Notes:** Commuter transit during peak hours. Passenger submitted a report for "Pothole" (Severity 4) at 18:36:02 as the vehicle pulled into the Banaybanay stop area over degraded curb pavement.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 1 (lane transition)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0
- **Events Observed but Not Detected by App:** 0 target driver behaviors.
- **Events Detected by App but Not Observed as Unsafe:** 1 turning event (standard lane transition).
- **Audit Assessment:** **Uncorroborated Behavioral Incident / Valid Road Surface Report.** Pothole was reported near destination curb; sensor detected 1 benign lane adjustment.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 7 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 21, 2026  
**Trip ID:** Trip 25 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Banaybanay → PNC Campus (via Katapatan Subdivision)  
**Vehicle Type:** Motorized Tricycle  
**Starting Point:** Lat 14.2562165, Lng 121.1289930 (Banaybanay)  
**Destination:** Lat 14.2615232, Lng 121.1551355 (PNC Campus)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

**1–8. Normal Tricycle Maneuvers (Street Intersection Cornering)**
- Approximate Timestamps: 18:02:10, 18:07:45, 18:14:20, 18:22:50, 18:35:10, 18:48:30, 19:05:15, 19:22:00
- Type: Normal 90-degree residential street turns
- Location: Local street corners across Banaybanay and Katapatan residential grid
- Audit Observation: Standard street corner turns executed at low speeds (< 18 km/h). Due to motorized tricycle steering geometry, normal 90-degree cornering naturally produces yaw angular velocity exceeding 1.5 rad/s without being hazardous swerves.

---

## TRIP SUMMARY

**Trip Duration:** 1 hr 44 min 16 sec (17:52:05 – 19:36:21)  
**Total Target Unsafe Behaviors:** 0  
**Total Normal Cornering Maneuvers:** 8  
**Computed Risk Score:** 0.40  

**Weather Conditions:** Overcast / Cloudy with intermittent light drizzle, damp road surfaces  
**Traffic Conditions:** Dense evening rush hour, frequent passenger stop-and-go in residential zone  
**Additional Notes:** Extended tricycle session. Passenger submitted a high-severity "Pothole" report (Severity 5) at 18:04:11 during a bumpy section along the Katapatan access road.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 8 (standard street corner turns)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0 direct matches with passenger report.
- **Events Observed but Not Detected by App:** 0 target driver violations.
- **Events Detected by App but Not Observed as Unsafe:** 8 turning events (standard tricycle corner turns registered by gyroscopic threshold).
- **Audit Assessment:** **Normal Tricycle Cornering Dynamics.** The 8 detections represent normal vehicle navigation through a residential street grid rather than unsafe driving. The pothole report documents physical road damage.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 8 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** August 21, 2026  
**Trip ID:** Trip 26 (User 1) — `saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db`  
**Route Corridor:** Banaybanay Corridor (Manila South Road, Cabuyao)  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2561317, Lng 121.1294467 (Banaybanay)  
**Destination:** Lat 14.2552954, Lng 121.1283229 (Banaybanay stop)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

**1–2. Normal Highway Maneuvers (Passive Road Curvature)**
- Approximate Timestamps: 21:54:10, 22:02:40
- Type: Normal roadway curvature turns (Non-Hazardous)
- Location: Manila South Road highway curves
- Audit Observation: Vehicle followed gentle road geometry along national highway; normal passenger transit.

---

## TRIP SUMMARY

**Trip Duration:** 17 min 43 sec (21:50:11 – 22:07:54)  
**Total Target Unsafe Behaviors:** 0  
**Total Normal Turns (Passive Curvature):** 2  
**Computed Risk Score:** 3.43  

**Weather Conditions:** Fair / Clear nighttime, dry roads, good streetlight illumination  
**Traffic Conditions:** Light to moderate nighttime arterial traffic flow  
**Additional Notes:** Nighttime jeepney ride. Passenger submitted a "Pothole" report (Severity 4) at 21:55:31 after the vehicle struck a sunken utility cover near the roadside.

---

## App Detection Results

- Speeding detected by app: 0
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 2 (passive roadway curves)

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0
- **Events Observed but Not Detected by App:** 0 driver behavioral violations.
- **Events Detected by App but Not Observed as Unsafe:** 2 turning events (gentle highway curves).
- **Audit Assessment:** **Valid Road Surface Hazard / Passive Road Curvature.** Passenger correctly documented physical roadway distress.

<div style="page-break-after: always;"></div>

---

# OBSERVATION SHEET 9 OF 9

**Lead Researcher / Auditor:** Nichoe Ashley B. De Jesus  
**Date:** September 7, 2026  
**Trip ID:** Trip 2 (User 2) — `saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db`  
**Route Corridor:** Cabuyao → Calamba → Los Baños Arterial Highway  
**Vehicle Type:** Public Utility Jeepney  
**Starting Point:** Lat 14.2476519, Lng 121.1295302 (Cabuyao)  
**Destination:** Lat 14.2034537, Lng 121.1547706 (Los Baños boundary)  
**Data Provenance:** Telemetry-Audited Route & Sensor Verification  

---

## EVENT RECORDS

- **Observation Windows:**
  - Window 1: 16:15:00 – 16:20:00 (encompasses 16:18:26 report)
  - Window 2: 16:42:00 – 16:46:00 (encompasses 16:44:45 and 16:44:57 reports)
- **Kinematic State:** Continuous arterial transit; recorded GPS speeds ranged between 32–48.2 km/h.
- **Observed Target Unsafe Behaviors:** None against the system's 60 km/h threshold.

---

## TRIP SUMMARY

**Trip Duration:** 45 min 28 sec (16:05:28 – 16:50:56)  
**Peak GPS Speed:** 48.2 km/h  
**Total Speeding Exceedances (> 60 km/h):** 0  
**Total Hard Braking Events:** 0  
**Total Sudden Direction Changes:** 0  
**Computed Risk Score:** 1.52  

**Weather Conditions:** Partly cloudy, warm afternoon sun, dry highway pavement  
**Traffic Conditions:** Moderate arterial traffic with intermittent slowdowns at major intersections  
**Additional Notes:** Three passenger reports for "Speeding" (all Severity 3) submitted at 16:18:26, 16:44:45, and 16:44:57 (the latter two 12 seconds apart). GPS telemetry confirms vehicle velocity peaked at 48.2 km/h and never breached the 60 km/h system threshold.

---

## App Detection Results

- Speeding detected by app: 0 (0 exceedances above 60 km/h)
- Hard braking detected by app: 0
- Sudden direction changes detected by app: 0

---

## Ground-Truth vs. App Comparison

- **Matching Events:** 0
- **Events Observed but Not Detected by App:** 0 against system threshold (Note: localized municipal limits such as 30 or 40 km/h cannot be evaluated without road-specific speed limit databases).
- **Events Detected by App but Not Observed:** 0
- **Audit Assessment:** **System Algorithm Adherence / Subjective Perception Discrepancy.** The passenger perceived 45–48 km/h as "Speeding" due to the open-cabin environment of the public utility jeepney. SafeRide strictly enforced its programmed 60 km/h cutoff, correctly registering 0 alarms. Reports 11 and 12 were submitted 12 seconds apart, confirming repeated submission.

---

## Master Cross-Trip Reconciled Audit Table

| Sheet | Trip ID | User | Date | Duration | Vehicle | Report Category | Severity | System Detections | Observed Normal Maneuver | Observed Unsafe Maneuver | Telemetry Audit Classification |
|:---:|:---:|:---:|---|---|---|---|:---:|---|---|---|---|
| **1** | 1 | U1 | Aug 1 | 29 s | Jeepney | Speeding | 3 | 0 | Stationary idling | None | **Kinematically Inconsistent** (Vehicle Stationary, 0 km/h) |
| **2** | 13 | U1 | Aug 14 | 11.5 min | Jeepney | Reckless Driving | 2 | 4 Turning | 4 Road curve turns | None | **Not Corroborated by Available Telemetry** (Passive Curves) |
| **3** | 16 | U1 | Aug 17 | 63 s | Jeepney | Pothole | 4 | 2 Turning | Intersection queue | None | **Plausible (Not Independently Verified)** (Sala Curb) |
| **4** | 18 | U1 | Aug 17 | 43 s | Jeepney | Pothole (×2) | 4, 4 | 4 Turning | Campus gate crawl | None | **Plausible (Not Independently Verified)** (PNC Approach) |
| **5** | 20 | U1 | Aug 19 | 7.5 min | Jeepney | Sudden Braking | 3 | 0 | Terminal queue wait | None | **Kinematically Inconsistent** (Parked at Terminal) |
| **6** | 22 | U1 | Aug 19 | 9.7 min | Jeepney | Pothole | 4 | 1 Turning | 1 Lane transition | None | **Plausible (Not Independently Verified)** (Banaybanay Curb) |
| **7** | 25 | U1 | Aug 21 | 104 min | Tricycle | Pothole | 5 | 8 Turning | 8 Street corner turns | None | **Plausible (Not Independently Verified)** (Katapatan Access) |
| **8** | 26 | U1 | Aug 21 | 17.7 min | Jeepney | Pothole | 4 | 2 Turning | 2 Road curve turns | None | **Plausible (Not Independently Verified)** (Sunken Cover) |
| **9** | 2 | U2 | Sep 7 | 45.5 min | Jeepney | Speeding (×3) | 3, 3, 3 | 0 | Cruising < 48.2 km/h | None | **Not Corroborated by Available Telemetry** (< 60 km/h Cutoff) |


