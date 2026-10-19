# APPENDIX E: FIELD-TESTING MASTER LOG AND GPS SUMMARY

This appendix provides the master field-testing log and GPS telemetry summary for the SafeRide retesting evaluation conducted in Cabuyao City, Laguna. All recorded trips were executed using production Android smartphones running the SafeRide client application, logging tri-axial accelerometer, gyroscope, and GPS coordinates continuously to local SQLite databases.

---

### Table E-1. Field-Testing Retesting Master Log (Seven Evaluated Trips, N = 3,108 s)

| Trip ID | Date | Start Time | End Time | Duration (s) | Route Corridor | Vehicle Type | GPS Fixes | GPS Tracking Status | Sensor Telemetry Status | Local SQLite Storage | Observer Sheet Completed |
|---|---|---|---|:---:|---|---|:---:|---|---|---|---|
| **PL-DZ-01** | 2026-10-04 | 13:26:55 | 13:31:25 | 270 | Pulo → Diezmo | Motorized Tricycle | 134 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 1) |
| **DZ-PL-02** | 2026-10-04 | 19:20:14 | 19:23:55 | 221 | Diezmo → Pulo | Motorized Tricycle | 110 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 2) |
| **BNY-SALA-03** | 2026-10-05 | 16:54:43 | 17:02:22 | 459 | Banaybanay → Sala | Public Utility Jeepney | 200 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 3) |
| **SALA-BNY-04** | 2026-10-05 | 21:58:31 | 22:01:49 | 198 | Sala → Banaybanay | Public Utility Jeepney | 44 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 4) |
| **BNY-PNC-05** | 2026-10-06 | 12:57:00 | 13:02:10 | 310 | Banaybanay → PNC | Motorized Tricycle | 160 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 5) |
| **PNC-BNY-06** | 2026-10-06 | 16:32:13 | 16:36:02 | 229 | PNC → Banaybanay | Motorized Tricycle | 125 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 6) |
| **CMC-LB-07** | 2026-09-18 | 20:54:42 | 21:18:23 | 1,421 | Calamba → Los Baños | Public Utility Jeepney | 200 | Fixed (Continuous) | Active (10 Hz) | Saved (`saferide.db`) | Yes (Sheet 7) |

*Total Field Evaluation Duration: **3,108 seconds** across 7 trips.*

---

### Table E-2. GPS Geographic Coordinate Bounds and Corridor Characteristics

| Trip ID | Origin Coordinates (Lat, Lng) | Destination Coordinates (Lat, Lng) | Road Classification | Pavement Type | Typical Speed (km/h) | Operational Hazards Observed |
|---|---|---|---|---|---|---|
| **PL-DZ-01** | 14.244136, 121.122063 | 14.243353, 121.119676 | Local Collector Road | Asphalt / Uneven Concrete | 15–28 | Surface depressions, narrow road shoulder |
| **DZ-PL-02** | 14.244421, 121.123002 | 14.246810, 121.125500 | Local Collector Road | Concrete | 18–30 | Roadway curve at Diezmo exit |
| **BNY-SALA-03** | 14.254586, 121.128547 | 14.269346, 121.125010 | National Highway Arterial (Manila South Rd) | Concrete / Asphalt overlay | 20–42 | High commuter density, gentle roadway curves |
| **SALA-BNY-04** | 14.269346, 121.125010 | 14.256678, 121.128163 | National Highway Arterial (Manila South Rd) | Concrete / Asphalt overlay | 25–48 | Aggressive overtaking, slow lead vehicles |
| **BNY-PNC-05** | 14.255000, 121.128000 | 14.262500, 121.135000 | Local Institutional Access Road | Concrete with Speed Humps | 10–25 | Pedestrian crossings, controlled humps |
| **PNC-BNY-06** | 14.262500, 121.135000 | 14.255000, 121.128000 | Local Institutional Access Road | Concrete with Speed Humps | 12–26 | Pedestrian crossings, dismissal congestion |
| **CMC-LB-07** | 14.212000, 121.165000 | 14.168000, 121.242000 | National Highway Arterial (Calamba–Los Baños Corridor) | Asphalt / Reinforced Concrete | 40–68 | Uncongested highway speeding, within-lane lateral sway |

---

### Traceability Connection to System Logs

1. **Physical Observation**: Recorded in the field on paper observation sheets (Appendix D) with observer name, start/stop times, and detailed event descriptions.
2. **GPS Record**: Stored in the `trips` table of `saferide.db`, with tracking breadcrumbs stored in latitude/longitude float arrays with Unix epoch timestamps.
3. **Sensor Record**: Processed using a 2-second sliding window with 50% overlap (1-second step size), segmenting sensor streams into contiguous 1-second evaluation windows.
4. **Matching Rule**: A temporal tolerance window of ±3 to ±5 seconds is applied between observer timestamps and system event timestamps.

---

### Data-Quality Note: `Verified By` Field in `saferide_passenger_reports.csv`

The `Verified By` column across all 124 records in `saferide_passenger_reports.csv` contains **bare empty values**. This accurately reflects the operational state of the SafeRide deployment: no formal external moderator or second human evaluator was assigned to independently verify individual commuter reports within the study period.

| Field | Value in CSV | Correct Interpretation |
|---|---|---|
| `Verified` | 123 = `false`, 1 = `true` | System flag; the one `true` record received community confirmation via in-app moderation |
| `Verified By` | All 124 = empty | **Missing data — no verifier identity was recorded**; not a data export error |
| `Verification Count` | All 124 = 0 | Zero independent confirmations; consistent with 109 pending community classifications in the hazard-validation master |

> **Important**: The `Verified By` field must **not** be described as a successfully populated verification field. The study did not implement a dual-observer independent verification protocol for individual passenger reports. This limitation is explicitly acknowledged in Chapter V, Recommendation 4.

