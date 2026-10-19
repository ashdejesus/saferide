# SAFERIDE PANEL DEFENSE EVIDENCE AUDIT & RECONCILIATION REPORT

**Study Title**: SafeRide: A Multi-Source Public Utility Vehicle Commuter Safety Monitoring and Hazard Reporting System  
**Document Type**: Panel Defense Evidence Reconciliation, Inter-Rater Reliability Audit, and Statistical Tool Justification  
**Date of Audit**: October 18, 2026 (Audited & Reconciled October 19, 2026)  
**Status**: Audit Completed; Selected Findings Verified, with Documented Limitations and Unresolved Data-Consistency Issues  

---

## Executive Summary & Evidence Verification Checklist

To address the thesis defense panel's comments regarding inter-rater reliability, ground-truth verification, and the statistical tools used in SOP 1, a comprehensive forensic audit was conducted on all SafeRide datasets, database archives, and export services.

### Evidence Audit & Verification Checklist (7 Audit Areas Addressed: Verified Evidence & Documented Limitations)

| Checklist Item | Audit Finding | Resolution & Supporting Artifact |
|---|---|---|
| **[X] 1. Recover and verify original sensor and ground-truth records for SOP 1** | The original window-level dataset was recovered and verified. It contains all **3,108 one-second continuous observation windows** across seven field trips. | Verified in `sop1_window_dataset.csv`, cross-referenced with contemporaneous Field Observation Sheets 1–7 (Appendix D) and Table F-1 (Appendix F). |
| **[X] 2. Establish paired independent-rater classifications for inter-rater reliability** | Independent human raters **did not** evaluate the same cases under a dual-blind protocol. Rater A is the reporting commuter; Rater B represents secondary community moderation (109 pending, 10 flagged absent, 5 confirmed present); 104 ground-truth records are inconclusive. | **Academic Honesty Position**: We do not claim human inter-rater reliability. We explicitly state this as an unmeasured limitation in Chapter IV and V, avoiding false assertions. |
| **[X] 3. Verify history of trust values and effect of reporting frequency on credibility (SOP 2.1)** | Available study records provide static snapshot values but do not contain a complete history of initial trust values, subsequent trust-score changes, or a report-by-report calculation log. | **Limitation Honestly Stated**: The numerical effect of reporting frequency on adaptive credibility scores cannot be independently verified from available records. Explicitly documented in Chapter IV, Chapter V, and Appendix G. |
| **[X] 4. Verify report-by-report sensor conformity and non-invalidation by sensor absence (SOP 2.2)** | Absence of a matching sensor event does not invalidate crowdsourced reports (e.g. slow potholes, discourtesy). The files lack report-by-report records showing how each concordance result changed trust scores. | **Limitation Honestly Stated**: The direct numerical effect of sensor conformity on adaptive credibility remains unverified. Documented in Chapter IV and Appendix G. |
| **[X] 5. Check missing trip IDs and verification fields in passenger-report data** | 35 reports possess valid Trip IDs (submitted during active trip monitoring); 89 are roadside hazard reports. An unquoted comma in Firestore timestamps previously shifted columns in CSV parsers. | Fixed timestamp serialization to ISO-8601; eliminated all column misalignments; properly quoted all text fields; validated 124 records across exactly 14 columns. |
| **[X] 6. Confirm why report-frequency totals equal 121 while report files contain 124 rows** | 12 of 13 passengers matched exactly. User `59C62FD...` had 53 cached reports in `passenger_trust_metrics` but 56 submitted reports in `passenger_reports` ($56 - 53 = 3$ delta; $121 + 3 = 124$). | Dynamically reconciled `Total Reports (Frequency)` with actual submitted report counts. Frequency sum now equals **exactly 124**. |
| **[X] 7. Recalculate only statistical measures supported by verified records** | All statistical calculations for SOP 1 (Confusion Matrix, Cohen's $\kappa$), SOP 2 (Tied-rank Spearman $\rho_s$), and SOP 3 (Wilcoxon Signed-Rank Test) were independently audited and verified. The GPS outlier count in `sop2_spearman_results.txt` was corrected from the erroneous value of 3 (script bug using hardcoded file-line count) to the verified value of **2** (confirmed by direct inspection of `saferide_passenger_reports.csv`). | Complete mathematical derivations and reproduction scripts provided in Chapter IV, Appendices D–H, and verification scripts. |

> [!WARNING]
> **Documented Limitations and Unresolved Issues — Do Not Claim Complete Verification**
> The following items remain unverified or unresolved in the available study records:
> - **Human inter-rater reliability was not measured.** Crowdsourcing gathered primary incident submissions; no paired dual-blind human observer protocol was applied.
> - **Historical trust-score changes cannot be independently verified.** `saferide_trust_metrics.csv` contains only a static snapshot; `saferide_trust_calculation_history.csv` is an algorithmic reconstruction/simulation, not a runtime ledger.
> - **The numerical effect of sensor conformity on credibility scores is unverified.** No report-by-report trust-update log exists.
> - **The Firebase cross-matched dataset has unresolved temporal and spatial inconsistencies.** Time deltas up to 431 minutes and distances up to 1.89 km exist between report and trip records.
> 
> These limitations are honestly disclosed throughout this document and the manuscript. They do not invalidate what was verified, but they prevent any claim of 100% complete empirical verification.

---

## 1. Forensic Audit of the Uploaded CSV Files

### A. Dataset 1: `saferide_hazard_validation_master.csv` (124 Records, 26 Columns)

- **Total Rows**: 124 evaluated incident records (`H-001` through `H-124`).
- **Rater A Classification**:
  - `Hazard Present`: **124** (100.0%)
  - *Analytical Rationale*: "Rater A" represents the primary reporting passenger. By submitting a report, the commuter asserts that a hazard or unsafe event occurred.
- **Rater B Classification (Secondary Community Consensus)**:
  - `Unrated (Pending)`: **109** (87.9%) — No secondary passenger encountered or interacted with the report pin.
  - `Hazard Absent (Flagged)`: **10** (8.1%) — Community passengers flagged the report as an inaccurate, road-curvature, or stationary artifact.
  - `Hazard Present (Confirmed)`: **5** (4.0%) — Community passengers verified and upvoted the report.
  - *Sum*: $109 + 10 + 5 = 124$ records.
- **Independent Ground Truth Status**:
  - `Inconclusive`: **104** records (36 Unverified Field Observations, 31 Unverified Maneuvers, 28 Contextually Plausible / Pending Photo GT, 9 Awaiting Independent Telemetry).
  - `Not Confirmed`: **11** records (6 Community Flagged False Alarms, 2 Road Curve Geometry Artifacts, 2 Stationary Boarding / Zero Velocity, 1 Smooth Braking / No Deceleration Anomaly).
  - `Confirmed`: **9** records (7 Gyroscope Angular Rate > 1.5 rad/s, 1 Road Surface Anomaly Consensus, 1 Longitudinal Deceleration < –3.5 m/s²).
  - *Sum*: $104 + 11 + 9 = 124$ records.

### B. Dataset 2: `saferide_passenger_reports.csv` (124 Records, 14 Columns)

- **Trip ID Audit**:
  - **35 reports** possess active `Trip ID` values (ranging from Trip 0 to Trip 259). These were submitted while the user was actively recording a trip within SafeRide, enabling direct linkage to onboard sensor telemetry.
  - **89 reports** have blank `Trip ID` fields. These represent crowdsourced hazard pins submitted directly via the spatial map or hazard reporting screen while the passenger was not actively running continuous trip monitoring.
- **Root Cause of the "Corrupt / Blank" Appearance**:
  - When exported from Firestore, the `timestamp` field was formatted as `Timestamp(seconds=..., nanoseconds=...)`.
  - Because that raw string contains an unquoted comma, standard CSV readers (Excel, Python, SPSS, R) split that single timestamp across two columns.
  - This column shift shifted the "Verified" column into the "Flagged" slot and made "Verified By" appear blank across the entire file.
  - **Correction Applied**: Timestamps have been converted to standard ISO-8601 strings (e.g., `2026-07-21T15:49:22.267Z`), and all string fields are enclosed in standard quotes. Every row now has **zero column mismatches** across all 14 columns.

### C. Dataset 3: `saferide_trust_metrics.csv` (13 Passenger Records, 6 Columns)

- **Discrepancy Analysis (121 vs 124)**:
  - 12 out of 13 passengers exhibited identical report counts between the trust metrics and passenger reports files (summing to 68 reports).
  - For Passenger `59C62FDg1QPkulakJIkf6ZpsAiD2`:
    - `saferide_trust_metrics.csv` showed `Total Reports (Frequency) = 53`.
    - `saferide_passenger_reports.csv` contained `56` reports.
    - Difference: **Exactly 3 reports** ($56 - 53 = 3$; $121 + 3 = 124$).
  - **Root Cause**: The Firestore document in the `passenger_trust_metrics` collection for user `59C` was calculated when 53 reports were present. Three subsequent reports were submitted without triggering the trust cache update. The export routine previously dumped the stale cached metric.
  - **Correction Applied**: `passenger_reporting_service.dart` has been updated to dynamically reconcile user report counts with actual submitted records. User `59C`'s frequency is now 56, and the sum across all 13 passengers is **exactly 124**.

### D. Audit of Adaptive Credibility & Reporting Frequency History (SOP 2.1)

- **Audit Findings**:
  - The available CSV export (`saferide_trust_metrics.csv`) captures only a single, cross-sectional state of final trust scores and cumulative report counts across the 13 contributing users.
  - While the underlying source code in `lib/services/trust_scoring_service.dart` implements the theoretical frequency saturation function ($F(n) = 1 - e^{-n/15}$, contributing 20% to overall trust), the database **does not record an event-driven delta ledger** or historical trajectory tracking how a user's score adjusted incrementally as each new report was filed.
- **Empirical Status**:
  - **The available study records do not contain a complete history of initial trust values, subsequent trust-score changes, or a report-by-report calculation log. Therefore, the numerical effect of reporting frequency on adaptive credibility scores cannot be independently verified from the available records.**
  - **Compliance Position**: This constraint is openly disclosed as an empirical limitation in the manuscript rather than claimed as verified.

### E. Audit of Sensor Conformity & Non-Invalidation by Sensor Absence (SOP 2.2)

- **Methodological Principle**:
  - In crowdsourced transit monitoring, **the absence of a matching sensor event should not automatically invalidate a report**. Many legitimate hazards—such as potholes navigated at walking speed, driver discourtesy, overloading, vehicle structural rattle, or stationary roadside hazards—do not trigger kinematic sensor threshold exceedances (accelerometer deceleration < –3.5 m/s² or gyroscope angular rate > 1.5 rad/s).
- **Audit Findings**:
  - In `saferide_hazard_validation_master.csv`, sensor concordance is noted where active telemetry was linked, but the Firestore records do not capture a report-by-report transaction log showing the step-by-step mathematical adjustment applied to `sensorAlignmentScore` and `overallTrust`.
- **Empirical Status**:
  - **The available files do not provide a complete report-by-report record showing how each concordance result changed the user’s trust score, so the direct numerical effect of sensor conformity on adaptive credibility remains unverified.**
  - **Compliance Position**: The manuscript emphasizes this principle to prevent false invalidation of commuter reports and honestly documents the absence of dynamic ledgering as an unverified evaluation boundary.

---

## 2. Resolving the Panel's Inter-Rater Reliability Question

### The Panel's Core Question
> *"Does the SafeRide study demonstrate inter-rater reliability, and did independent raters agree?"*

### Transparent and Defensible Answer
**No, the uploaded crowdsourced records do not establish human inter-rater reliability, and Cohen's kappa must NOT be reported as a human inter-rater statistic for SOP 2.**

```
+---------------------------------------------------------------------------------+
|                       CRITICAL DISTINCTION IN SAFERIDE                          |
+---------------------------------------------------------------------------------+
|  SOP 1: System-to-Reference Concordance     |  SOP 2: Human Inter-Rater Reliability|
|  - Compares: Automated Sensor Detector      |  - Compares: Two Independent Human   |
|    versus Physical Ground-Truth Observer    |    Raters evaluating the same event  |
|  - Evaluated on: 3,108 one-second windows   |  - Status: NOT MEASURED in study     |
|  - Cohen's Kappa: κ = 0.7995 (Substantial)  |  - Reason: Commuter crowdsourcing    |
|  - Valid: Measures detector performance     |    collects primary incident pins,   |
|    correcting for transit class imbalance.  |    not dual-blind paired ratings.    |
+---------------------------------------------------------------------------------+
```

### Why Human Inter-Rater Reliability Cannot Be Claimed
1. **Asymmetric Protocol**: All 124 records have Rater A = "Hazard Present". This is because Rater A is the commuter who submitted the incident report. There was no second evaluator independently rating all 124 locations.
2. **Missing Paired Observations**: 109 of the 124 records (87.9%) have Rater B = "Unrated (Pending)". Only 15 records received secondary community moderation.
3. **Inconclusive Physical Evidence**: 104 of the 124 records are classified as "Inconclusive" ground truth because passive smartphone sensors cannot physically confirm potholes or driver conduct without on-site photographic evidence or contemporaneous observer logs.
4. **Action Taken in Manuscript**: In [Chapter IV](file:///c:/Users/nicho/Documents/GitHub/saferide/CHAPTER_IV_V_FINAL_DEFENSE_REVISION.md#L96-L98) and [Chapter V](file:///c:/Users/nicho/Documents/GitHub/saferide/CHAPTER_IV_V_FINAL_DEFENSE_REVISION.md#L355-L357), we explicitly state that **human inter-rater reliability was not evaluated**. We present SOP 2 strictly as an **exploratory monotonic correlation** between sensor anomaly frequencies and commuter-reported severity (Spearman's $\rho_s$), while listing a formal dual-observer inter-rater reliability protocol as Recommendation 4 for future research.

---

## 3. SOP 1: Sensor Detection Performance & Statistical Tools

### The Statistical Tools Used in SOP 1

| Tool / Metric | Mathematical Purpose in SOP 1 | Sample Size & Data Unit |
|---|---|---|
| **2x2 Confusion Matrix** | Cross-tabulates automated sensor detections against physical observer ground truth | $N = 3,108$ contiguous 1-second observation windows across 7 trips |
| **Observed Accuracy ($P_o$)** | Total proportion of correct window classifications: $(TP + TN) / N$ | 99.90% ($3,105 / 3,108 = 0.999035$) |
| **Expected Chance Agreement ($P_e$)** | Quantifies probability of agreement by chance given the marginal distributions | 99.52% ($0.995185$) |
| **Cohen's Kappa ($\kappa$)** | Corrects observed agreement for chance under extreme time-series class imbalance | **$\kappa = 0.7995$** (Substantial agreement under Landis & Koch, 1977) |
| **Precision (PPV)** | Proportion of system detections that corresponded to real physical events: $TP / (TP + FP)$ | **66.67%** ($6 / 9$) |
| **Recall (Sensitivity)** | Proportion of observed ground-truth events detected by system: $TP / (TP + FN)$ | **100.00%** ($6 / 6$) |
| **Specificity** | Proportion of non-event transit windows correctly classified as negative: $TN / (TN + FP)$ | **99.90%** ($3,099 / 3,102$) |
| **F1-Score** | Harmonic mean of precision and recall: $2 \cdot (Prec \cdot Rec) / (Prec + Rec)$ | **0.8000** |

### Complete 2x2 Confusion Matrix (Seven Evaluated Trips, N = 3,108 Windows)

```
                              SafeRide Detection
                         Event Present   Event Absent    Row Total (Ground Truth)
                       +---------------+---------------+
Observer: Event Present|     6 (TP)    |     0 (FN)    |            6
                       +---------------+---------------+
Observer: Event Absent |     3 (FP)    |  3,099 (TN)   |        3,102
                       +---------------+---------------+
Column Total (System)  |     9         |  3,099        |   N = 3,108 Windows
                       +---------------+---------------+
```

### Event-Level Classification Breakdown
- **True Positives (TP = 6)**:
  1. *Trip SALA-BNY-04 (22:01:44)*: Sharp overtaking swerve into oncoming lane (lateral angular velocity > 1.5 rad/s).
  2. *Trip CMC-LB-07 (21:06:00)*: Sustained speeding > 60 km/h on uncongested national highway segment.
  3. *Trip CMC-LB-07 (21:00:00, 21:03:00, 21:09:00, 21:14:00)*: Four physical within-lane lateral sway / hovering maneuvers at highway speed.
- **False Positives (FP = 3)**:
  - *Trip DZ-PL-02 (19:20:54)*: Road curvature along Diezmo road bend triggered gyroscope (> 1.5 rad/s) without driver swerving.
  - *Trip BNY-SALA-03 (16:55:20 & 16:57:35)*: Natural roadway curves along provincial highway corridor triggered lateral threshold.
- **False Negatives (FN = 0)**:
  - All physically documented driving events were captured by the sensor threshold pipeline.
- **True Negatives (TN = 3,099)**:
  - Contiguous seconds of normal, steady transit correctly classified as non-hazardous.

### Comparative Baseline: Local Cabuyao Trips ($N = 1,687$ Windows)
When evaluating solely the six local urban trips (PL-DZ-01 through PNC-BNY-06), where no high-speed highway segments existed and only one organic swerve occurred:
- $TP = 1, FP = 3, FN = 0, TN = 1,683$
- Accuracy: **99.82%**
- Cohen's Kappa: **$\kappa = 0.3994$** (Fair-to-moderate agreement)
- Precision: **25.00%** ($1/4$)
- Recall: **100.00%** ($1/1$)
- F1-Score: **0.4000**
- *Analytical Insight*: Demonstrates that SafeRide's detection performance is route-dependent. Local urban routes with frequent bends produce roadway curve false positives, whereas arterial highway transit exhibits high statistical concordance ($\kappa = 0.7995$).

---

## 4. SOP 2 and SOP 3 Summary of Verified Records

### SOP 2: Passenger Reports vs. Sensor Anomalies & Dataset Reconciliation

#### A. Variable Definitions and Evidentiary Framing
- **Sensor Variable ($Y$)**: Trip-level count of physical driving anomalies, defined as $Y = \text{speedingCount} + \text{brakingCount} + \text{turningCount}$ accumulated over the entire trip.
- **Passenger Variable ($X$)**: Commuter's reported incident-severity rating on an ordinal 1-to-5 scale.
- **Evidentiary Interpretation**: The relationship is interpreted strictly as an **exploratory association in the matched sample**, and **not as proof that sensor anomalies predict incident severity**.

#### B. Statistical Results & Unit of Analysis
- **Report-Level (Exploratory)**: Evaluated across $n = 12$ matched reports from SQLite databases (`export data/SR/`). Exact tied-rank Spearman correlation yields $\rho_s = \mathbf{+0.5999} \approx \mathbf{+0.60}$ ($t = 2.37, df = 10, p = \mathbf{0.039}$), which is **statistically significant** at $\alpha = 0.05$.
- **Trip-Level (Conservative Aggregation)**: When collapsed by unique trip ($N = 9$ unique trips), correlation moderates to $\rho_s = \mathbf{+0.5049} \approx \mathbf{+0.50}$ ($t = 1.55, df = 7, p = \mathbf{0.165}$), which is **not statistically significant**.

#### C. Four Mandatory Methodological Limitations
1. **Small Sample Size**: Only 12 matched reports across 9 unique trips, providing low statistical power.
2. **Dominant Passenger and User Clustering**: All 12 reports originated from only two users (`User 1` contributed 9 reports; `User 2` contributed 3 reports on Trip 2), violating statistical independence.
3. **Unmatched Records**: 112 out of 124 passenger reports in Firebase could not be linked to sensor logs because they were submitted outside active trips, retrospectively, or on unarchived devices.
4. **Absence of Incident-Specific Sensor Windows**: Sensor event counts represent aggregate trip totals rather than localized sensor activity within a narrow window (e.g., $\pm 5$ min or $\pm 150$ m) around the reported incident coordinates.

#### D. Reconciliation: Native SQLite ($n=12$) vs. Firebase Cross-Matched ($n=11$) — Critical Remaining Issues

**Critical Issue A — Temporal and Spatial Inconsistency in the Firebase Cross-Matched Dataset**:

A critical review of `export data/sop2_matched_dataset.csv` reveals large discrepancies between report timestamps and trip-start times. The first matched record shows a report timestamp of approximately **13:26** and a trip start of approximately **20:36** — a difference of approximately **431 minutes (7.2 hours)**. Its GPS coordinates are approximately **1.89 km** from the trip start location. Other rows exhibit similarly large temporal and spatial gaps. Because matching was performed via Trip ID string matching across user collections (not same-user in-trip logging), the shared Trip ID does not establish that the report and sensor session correspond to the same incident. **This 11-record dataset must be labeled a cross-matched sensitivity analysis with unresolved temporal and spatial consistency, not validated incident-level evidence.** All results from this pipeline are disclosed for transparency only.

**Critical Issue B — Report Count Reconciliation (124 vs. 122)**:

The `sop2_spearman_results.txt` file states 122 reports were loaded (not 124), because 2 records with GPS coordinates outside the Philippines (San Francisco, CA; Lat ≈37.42, Lon ≈−122.08) were excluded as GPS outliers. Arithmetic verification: $124 - 2 = 122$ (loaded); $11 + 111 = 122$ (matched + unmatched) ✓. An earlier script comment referenced "3 outliers" — the operationally applied exclusion was **2 records**. The two pipelines must be tracked independently:

| Pipeline | Master Export | Excluded | Loaded | Matched | Unmatched |
|---|:---:|:---:|:---:|:---:|:---:|
| **Native SQLite (PRIMARY)** | 124 | — | 124 | **12** | 112 |
| **Firebase Cross-Matched (SENSITIVITY)** | 124 | 2 GPS outliers | **122** | **11** | **111** |

A critical audit question concerned the relationship between the primary SQLite finding and the secondary Firebase cross-matched pipeline:
- **Primary Finding (Native SQLite, $n = 12$)**: Derived directly from SQLite client `.db` files (`saferide_user_*.db`) where `trip_id` was natively logged in-trip. Covers 2 users across trips with 0–8 events (including Trip 25, severity 5, 8 events), yielding $\rho_s = +0.60, p = 0.039$. This represents the primary, reproducible exploratory dataset.
- **Secondary Pipeline (Firebase Cross-Matched, $n = 11$)**: Derived by matching Firebase crowdsourced reports to `.db` trips via Trip ID string matching across user collections. This dataset produced $\rho_s = -0.8864, p = 0.0003$, but **10 of the 11 records (90.9%) were contributed by a single user** (`5y0AF7w3`). Additionally, large temporal ($\Delta t$ up to 431 min) and spatial ($\Delta d \approx 1.89$ km) discrepancies between report timestamps/coordinates and trip-start timestamps/coordinates have been identified. **This pipeline must be labeled as a cross-matched sensitivity analysis with unresolved temporal and spatial consistency.**
- **Dominant Passenger Sensitivity Test**: When user `5y0AF7w3` is excluded, the usable sample **collapses to $n = 1$**, making correlation calculation mathematically impossible. Excluding the single minority passenger leaves $n = 10$ with $\rho_s = -0.9129$, which simply mirrors that single individual's behavior.
- **Reconciliation Verdict**: The two datasets represent different underlying subsets using different matching methods. The native SQLite $n=12$ dataset is retained as the **primary exploratory finding**. The $n=11$ pipeline serves as a sensitivity demonstration — one with **unresolved temporal and spatial consistency** — confirming that cross-matched crowdsourced data are heavily dominated by individual user behavior and cannot support generalized predictive claims.

### SOP 3: Composite Risk Score Differentiation
- **Statistical Tool**: Wilcoxon Signed-Rank Test on paired differences ($D = \text{Risk}_{\text{trip}} - \text{Risk}_{\text{sens}}$).
- **Evaluated Sample**: All 9 unique trips from SOP 2 ($N = 9$).
- **Handling of Zero Differences**: Trips 1 and 20 had $D = 0.0000$ and were dropped, yielding $N_{\text{diff}} = 7$ non-zero paired differences.
- **Test Results**:
  - $W^+ = 28.0, W^- = 0.0$
  - Test Statistic: $W = \mathbf{0.0}$
  - Exact Two-Tailed $p$-value: $p = 2 \times (0.5)^7 = \mathbf{0.0156}$ ($p < 0.05$).
  - *Conclusion*: Composite risk scores are systematically higher than sensor-only scores when passenger reports are present. Confirms multi-source fusion algorithm function, but does not prove real-world collision prediction accuracy.
- **Scale Analysis ($N = 150$ Trips)**: Spearman's $\rho_s = +0.6146$ ($p < 0.0001$). Explicitly acknowledged as reflecting internal mathematical model coupling.

---

### 5. Artifact and Repository Alignment

All datasets and evidence files in the repository have been synchronized and placed in the official evidence folders:

1. **`export data/sop1_window_dataset.csv`** & **`SAFERIDE FINAL DEFENSE REVISION EVIDENCE/02_SOP1_VALIDATION/sop1_window_dataset.csv`**:
   - Complete 3,108 one-second observation windows with ground-truth and system predictions.
2. **`panel_review_csvs/saferide_passenger_reports.csv`** & **`SAFERIDE FINAL DEFENSE REVISION EVIDENCE/06_PANEL_RESPONSE/saferide_passenger_reports.csv`**:
   - 124 pristine records, ISO-8601 timestamps, quoted strings, zero column misalignments.
3. **`panel_review_csvs/saferide_trust_metrics.csv`** & **`SAFERIDE FINAL DEFENSE REVISION EVIDENCE/06_PANEL_RESPONSE/saferide_trust_metrics.csv`**:
   - 13 passenger records, frequency sum reconciled to **exactly 124**.
4. **`panel_review_csvs/saferide_hazard_validation_master.csv`** & **`SAFERIDE FINAL DEFENSE REVISION EVIDENCE/06_PANEL_RESPONSE/saferide_hazard_validation_master.csv`**:
   - 124 traceable records detailing Rater A (passenger report), Rater B (community moderation: 109 pending, 10 flagged, 5 confirmed), and ground truth (104 inconclusive).
5. **`export data/sop2_matched_dataset.csv`** (Firebase Cross-Matched — **Sensitivity Analysis Only with Unresolved Temporal/Spatial Consistency**):
   - 11 records matched via Trip ID string matching across user collections. **Not validated incident-level evidence.** Large temporal ($\Delta t$ up to 431 min) and spatial ($\Delta d \approx 1.89$ km) discrepancies identified. Must be labeled as a cross-matched sensitivity analysis until source timestamps, time zones, Trip ID mapping, and coordinates are independently verified.
6. **`saferide_trust_calculation_history.csv`** (Reconstructed Simulation — **Not an Observed Historical Ledger**):
   - Generated by a script initializing trust scores at 0.5000 and recalculating using assumed cumulative report counts, prior severity values, and sensor events. **This file is an algorithmic reconstruction / simulation that demonstrates the calculation procedure.** It does not establish that the recorded trust changes occurred in the application at the timestamps shown. Must not be presented as a recovered empirical history or independent verification of actual runtime trust-score changes.
7. **Manuscript Alignment**:
   - [CHAPTER_IV_V_FINAL_DEFENSE_REVISION.md](file:///c:/Users/nicho/Documents/GitHub/saferide/CHAPTER_IV_V_FINAL_DEFENSE_REVISION.md) and [APPENDICES_D_TO_H_FINAL_DEFENSE_EVIDENCE.md](file:///c:/Users/nicho/Documents/GitHub/saferide/APPENDICES_D_TO_H_FINAL_DEFENSE_EVIDENCE.md) are aligned with these exact numbers, tables, critical-issue disclosures, and academic qualifications.
