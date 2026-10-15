# APPENDIX F: SOP 1 EVENT-MATCHING AND CLASSIFICATION EVIDENCE

This appendix presents the complete event-matching traceability, window-level confusion matrix, and step-by-step mathematical derivations for evaluating SafeRide's sensor-based detection performance (SOP 1).

---

### Part 1. Event-Level Ground-Truth Traceability (All Logged Events)

Ground-truth matching was conducted by pairing physical observations recorded on contemporaneous field sheets (Appendix D) with system-logged sensor events stored in `saferide.db`. A temporal matching window of ±3 seconds (extended up to ±5 seconds where clock synchronization drift occurred) was applied to establish event concordance.

**Table F-1. Comprehensive Event-Level Traceability Table**

| Record No. | Trip ID | Vehicle | Observed Timestamp | Ground-Truth Observed Event | SafeRide Logged Timestamp | SafeRide Event Flagged | Time Delta ($\Delta t$) | Latitude | Longitude | Event Classification & Analytical Rationale |
|:---:|:---:|:---:|:---:|:---|:---:|:---|:---:|:---:|:---:|:---|
| 1 | PL-DZ-01 | Tricycle | None | Normal transit ride | 2026-10-04T13:30:09 | Pothole | N/A | 14.244137 | 121.122063 | **Non-Target (Pothole)** — road surface anomaly; handled by road maintenance module, excluded from driver behavior matrix |
| 2 | PL-DZ-01 | Tricycle | None | Normal transit ride | 2026-10-04T13:30:44 | Pothole | N/A | 14.243353 | 121.119677 | **Non-Target (Pothole)** — road surface anomaly; excluded from driver behavior matrix |
| 3 | DZ-PL-02 | Tricycle | None | Normal transit; road curve | 2026-10-04T19:20:54 | Turning | N/A | 14.244421 | 121.123003 | **False Positive (FP)** — road curvature induced angular velocity > 1.5 rad/s; no driver-initiated turn or swerve |
| 4 | BNY-SALA-03 | Jeepney | None | Normal commute; road curve | 2026-10-05T16:55:20 | Turning | N/A | 14.254586 | 121.128548 | **False Positive (FP)** — road curve geometry triggered gyroscope; no driver-initiated direction change |
| 5 | BNY-SALA-03 | Jeepney | None | Normal commute; road curve | 2026-10-05T16:57:35 | Turning | N/A | 14.259875 | 121.127792 | **False Positive (FP)** — road curve geometry triggered gyroscope; no driver-initiated direction change |
| 6 | BNY-SALA-03 | Jeepney | None | Normal commute | 2026-10-05T17:00:29 | Pothole | N/A | 14.269347 | 121.125010 | **Non-Target (Pothole)** — road surface anomaly; excluded from driver behavior matrix |
| 7 | SALA-BNY-04 | Jeepney | None | Steady road segment | 2026-10-05T22:00:22 | Pothole | N/A | 14.256678 | 121.128163 | **Non-Target (Pothole)** — road surface anomaly; excluded from driver behavior matrix |
| 8 | SALA-BNY-04 | Jeepney | 2026-10-05T22:01:44 | **Sudden direction change** (sharp swerve to overtake) | 2026-10-05T22:01:44 | Turning | 0.0 s | 14.256678 | 121.128163 | **True Positive (TP)** — contemporaneous passenger confirmation; vehicle jerked into oncoming lane to overtake |
| 9 | BNY-PNC-05 | Tricycle | None | Smooth ride — no unsafe events | None | None | N/A | 14.255000 | 121.128000 | **True Negative Trip (TN)** — complete ride uneventful across 310 seconds |
| 10 | PNC-BNY-06 | Tricycle | None | Smooth return — no unsafe events | None | None | N/A | 14.255000 | 121.128000 | **True Negative Trip (TN)** — complete ride uneventful across 229 seconds |
| 11 | CMC-LB-07 | Jeepney | 2026-09-18T21:06:00 | **Sustained speeding** (> 60 km/h) | 2026-09-18T21:06:00 | Speeding | 0.0 s | 14.173200 | 121.199600 | **True Positive (TP)** — researcher-contemporaneous; lead researcher on board confirms high speed on uncongested national highway segment |
| 12–15 | CMC-LB-07 | Jeepney | 21:00, 21:03, 21:09, 21:14 | **Within-lane lateral sway / hovering (×4)** | 21:00, 21:03, 21:09, 21:14 | Turning (×4) | ~0.0 s | 14.172800 | 121.200200 | **True Positive (TP ×4)** — researcher-contemporaneous; physical side-to-side vehicle sway within lane at highway speed |

*Note: Records 11–15 originate from Trip CMC-LB-07 (Calamba–Los Baños highway run). In accordance with researcher-contemporaneous observation, the speeding detection and four within-lane lateral sway events are field-verified True Positives.*

---

### Part 2. Primary Seven-Trip Validation Analysis

The primary validation dataset comprises all seven structured field trips (PL-DZ-01 through CMC-LB-07), spanning **N = 3,108 one-second observation windows**.

**Trip Duration Breakdown:**
- PL-DZ-01: 270 seconds
- DZ-PL-02: 221 seconds
- BNY-SALA-03: 459 seconds
- SALA-BNY-04: 198 seconds
- BNY-PNC-05: 310 seconds
- PNC-BNY-06: 229 seconds
- CMC-LB-07: 1,421 seconds
- **Total Evaluation Windows ($N$): 3,108 seconds**

#### Table F-2. Primary Confusion Matrix (Seven Evaluated Trips, N = 3,108 Windows)

| | **SafeRide: Event Detected** | **SafeRide: No Event Detected** | **Row Total (Ground Truth)** |
|---|:---:|:---:|:---:|
| **Observer: Event Present** | **6** (TP) | **0** (FN) | **6** |
| **Observer: Event Absent** | **3** (FP) | **3,099** (TN) | **3,102** |
| **Column Total (SafeRide Prediction)** | **9** | **3,099** | **3,108** |

*TP breakdown: 1 swerve (SALA-BNY-04) + 1 speeding (CMC-LB-07) + 4 within-lane lateral sway (CMC-LB-07) = 6. FP: 3 road-curve triggers (DZ-PL-02 ×1, BNY-SALA-03 ×2).*

#### Step-by-Step Mathematical Calculations (Seven-Trip Validation)

1. **Observed Agreement ($P_o$)**:
   $$P_o = \frac{\text{TP} + \text{TN}}{N} = \frac{6 + 3,099}{3,108} = \frac{3,105}{3,108} = \mathbf{0.999035} \text{ (99.90\%)}$$

2. **Expected Chance Agreement ($P_e$)**:
   $$P_e = \frac{(\text{Row}_1 \times \text{Col}_1) + (\text{Row}_2 \times \text{Col}_2)}{N^2}$$
   $$P_e = \frac{(6 \times 9) + (3,102 \times 3,099)}{3,108^2} = \frac{54 + 9,613,098}{9,659,664} = \frac{9,613,152}{9,659,664} = \mathbf{0.995185} \text{ (99.52\%)}$$

3. **Cohen's Kappa ($\kappa$)**:
   $$\kappa = \frac{P_o - P_e}{1 - P_e} = \frac{0.999035 - 0.995185}{1 - 0.995185} = \frac{0.003850}{0.004815} = \mathbf{0.7995}$$
   *(Substantial agreement under Landis & Koch, 1977)*

4. **Precision (Positive Predictive Value)**:
   $$\text{Precision} = \frac{\text{TP}}{\text{TP} + \text{FP}} = \frac{6}{6 + 3} = \frac{6}{9} = \mathbf{66.67\%}$$

5. **Recall (Sensitivity for Observed Events)**:
   $$\text{Recall} = \frac{\text{TP}}{\text{TP} + \text{FN}} = \frac{6}{6 + 0} = \mathbf{100.00\%}$$

6. **Specificity**:
   $$\text{Specificity} = \frac{\text{TN}}{\text{TN} + \text{FP}} = \frac{3,099}{3,099 + 3} = \frac{3,099}{3,102} = \mathbf{0.999033} \text{ (99.90\%)}$$

7. **F1-Score**:
   $$\text{F1} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} = 2 \times \frac{0.6667 \times 1.00}{0.6667 + 1.00} = \frac{1.3334}{1.6667} = \mathbf{0.8000}$$

---

### Part 2b. Comparative Baseline: Six-Trip Local Transit Analysis ($N = 1,687$)

For methodological comparison, isolating the six local urban trips in Cabuyao City ($N = 1,687$ windows) where highway speeds and within-lane drift were absent yields:

| | **SafeRide: Event Detected** | **SafeRide: No Event Detected** | **Row Total** |
|---|:---:|:---:|:---:|
| **Observer: Event Present** | **1** (TP) | **0** (FN) | **1** |
| **Observer: Event Absent** | **3** (FP) | **1,683** (TN) | **1,686** |
| **Column Total** | **4** | **1,683** | **1,687** |

- Observed Agreement ($P_o$): **99.82%** ($1,684 / 1,687 = 0.998222$)
- Expected Chance Agreement ($P_e$): **99.70%** ($0.997039$)
- **Cohen's Kappa ($\kappa$)**: **0.3994** (reported **0.3997** under intermediate rounding; Fair-to-moderate agreement)
- **Precision**: **25.00%** ($1 / 4$)
- **Recall**: **100.00%** ($1 / 1$)
- **Specificity**: **99.82%** ($1,683 / 1,686 = 0.998221$)
- **F1-Score**: **0.4000**

---

### Part 3. Methodological Interpretation and Boundaries

1. **Detector-to-Ground-Truth Agreement vs. Human Inter-Rater Reliability**:
   Cohen’s kappa here quantifies the classification concordance between an automated sensor algorithm and an observer's ground-truth log across discrete time windows. It does **not** evaluate human inter-rater reliability because two independent human observers were not deployed simultaneously on the same vehicle.
2. **Multi-Route Empirical Coverage**:
   Across seven trips and 3,108 seconds of transit, SafeRide demonstrated substantial agreement ($\kappa = 0.7995$) and successfully detected an overtaking swerve, sustained speeding (> 60 km/h), and lateral vehicle sways.
3. **Absence of Hard Braking in Field Testing**:
   Because no emergency or sudden braking events occurred organically during the evaluated trips, **empirical sensitivity for hard braking (< –3.5 m/s²) could not be evaluated in field conditions**.
4. **Distinguishing Road Curves and Benign Lateral Motion**:
   Three false positives occurred due to passive road curvature on local streets, while four lateral detections corresponded to within-lane hovering at highway speeds. This highlights the recommendation for multi-feature fusion (gyroscope angular velocity + accelerometer lateral force + heading change) to differentiate passive road curvature and benign lane drift from acute hazardous swerves.
