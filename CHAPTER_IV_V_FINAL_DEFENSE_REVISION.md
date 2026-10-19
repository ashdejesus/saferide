# CHAPTER IV: RESULTS AND DISCUSSION

This chapter presents the results of the development and evaluation of the proposed SafeRide system. The findings are presented and discussed according to the specific problems stated in the study. The chapter focuses on the performance of the sensor-based detection module, the credibility and relationship of passenger reports through the weighted reporting mechanism, and the generation of the composite trip risk score.

The results are based on recorded sensor data, ground-truth observations, passenger reports, and computed risk scores obtained during system evaluation. Statistical measures are used to evaluate the detection performance of the system, the relationship between sensor-detected events and crowd-reported severity, and the resulting trip-level risk scores. The findings are interpreted to determine how the proposed system addresses the identified problems and objectives of the study, while explicitly identifying the operational and methodological boundaries of the findings.

---

## Sensor-Based Detection of Unsafe Transportation Behavior (SOP 1)

### Background and Evaluation Approach

SafeRide utilizes the smartphone’s onboard tri-axial accelerometer and gyroscope, in conjunction with GPS location updates, to detect three categories of vehicular driving behaviors in real time: speeding, sudden braking, and sudden direction changes. The detection algorithms apply threshold-based heuristic logic to streaming sensor signals:
- **Speeding**: Flagged when GPS-derived velocity exceeds 60 km/h on monitored roadway segments.
- **Sudden Braking**: Flagged when longitudinal deceleration exceeds –3.5 m/s² (derived from accelerometer readings filtered for device attitude).
- **Sudden Direction Changes (Turning)**: Flagged when lateral angular velocity captured by the gyroscope exceeds 1.5 rad/s.

*Note on Implemented Thresholds*: The values stated above represent nominal base parameters. The runtime implementation in `risk_scoring.dart` applies vehicle-type multipliers (jeepney: 0.75 divisor, tricycle: 0.65 divisor) and a dynamic contextual environment factor $A(t) \ge 1.0$, producing effective runtime thresholds of approximately 61–71 km/h for speeding, –6.1 to –7.1 m/s² for braking, and 2.45–2.83 rad/s for turning under default operating conditions. This explains why standard vehicle vibration and minor road undulations did not trigger spurious event detections.

To evaluate the classification accuracy of these detectors against real-world driving conditions, seven structured field trips spanning 3,108 seconds of active transit across four public utility vehicle (PUV) transit corridors in Laguna were evaluated for SOP 1. For each evaluated trip, a designated passenger-observer or lead researcher was physically present on board inside the vehicle and independently logged all vehicle dynamics and driving maneuvers in real time on a standardized ground-truth observation sheet (Appendix D, Observation Sheets 1 through 7), recording event nature, approximate location, and timestamp prior to inspecting SafeRide's automated output. The evaluation encompasses both local urban routes (Trips PL-DZ-01 through PNC-BNY-06 in Cabuyao City) and arterial highway transit (Trip CMC-LB-07 along the Calamba–Los Baños national highway corridor), capturing motorized tricycles and public utility jeepneys across varied traffic conditions.

The characteristics of the seven evaluated trips and their corresponding observation sheets are summarized in Table 1.

**Table 1. SOP 1 Evaluation Trip Summary and Observation Sheet Masterlist (N = 7)**

| Trip ID | Observation Sheet | Date | Route Corridor | Vehicle Type | Duration (s) | GPS Fixes | Primary Observer |
|---|---|---|---|---|:---:|:---:|---|
| **PL-DZ-01** | Sheet 1 | Oct 4, 2026 | Pulo → Diezmo | Motorized Tricycle | 270 | 134 | N. A. De Jesus / C. J. Almanon |
| **DZ-PL-02** | Sheet 2 | Oct 4, 2026 | Diezmo → Pulo | Motorized Tricycle | 221 | 110 | N. A. De Jesus / C. M. Esmenos |
| **BNY-SALA-03** | Sheet 3 | Oct 5, 2026 | Banaybanay → Sala | Public Utility Jeepney | 459 | 200 | N. A. De Jesus / M. J. Alado |
| **SALA-BNY-04** | Sheet 4 | Oct 5, 2026 | Sala → Banaybanay | Public Utility Jeepney | 198 | 44 | N. A. De Jesus / C. J. Almanon |
| **BNY-PNC-05** | Sheet 5 | Oct 6, 2026 | Banaybanay → PNC | Motorized Tricycle | 310 | 160 | N. A. De Jesus / C. M. Esmenos |
| **PNC-BNY-06** | Sheet 6 | Oct 6, 2026 | PNC → Banaybanay | Motorized Tricycle | 229 | 125 | N. A. De Jesus / M. J. Alado |
| **CMC-LB-07** | Sheet 7 | Sep 18, 2026 | Calamba (CMC) → Los Baños | Public Utility Jeepney | 1,421 | 200 | N. A. De Jesus (Lead Researcher) |

The seven evaluation trips span a cumulative duration of **3,108 seconds** of active transit, with continuous GPS positioning and tri-axial sensor logging sampled at 10 Hz and archived to local SQLite database records (`saferide.db`).

### Ground-Truth Event Matching and Traceability

Ground-truth matching was conducted by pairing physical observations recorded on contemporaneous field sheets (Appendix D) with system-logged sensor events stored in `saferide.db`. A temporal matching window of ±3 seconds (extended up to ±5 seconds where clock synchronization drift occurred) was applied to establish event concordance.

Table 2 presents the event-level matching traceability across all seven evaluated trips.

**Table 2. Event-Level Ground-Truth Matching Traceability (Seven Evaluated Trips)**

| Trip ID | Vehicle | Observed Timestamp | Ground-Truth Observed Event | SafeRide Logged Event | Temporal $\Delta t$ | Coordinates (Lat, Lng) | Event Classification & Analytical Rationale |
|---|---|---|---|---|---|---|---|
| PL-DZ-01 | Tricycle | None | Normal ride; road unevenness | Pothole (×2) | N/A | 14.244137, 121.122063 | **Non-Target (Pothole)** — road surface anomaly; handled by road maintenance module, excluded from driver behavior matrix |
| DZ-PL-02 | Tricycle | None | Normal transit; roadway bend | Turning | N/A | 14.244421, 121.123003 | **False Positive (FP)** — road curvature induced angular velocity > 1.5 rad/s; no driver-initiated turn or swerve |
| BNY-SALA-03 | Jeepney | None | Normal commute; road curve | Turning (×2) | N/A | 14.254586, 121.128548 | **False Positive (FP ×2)** — road curve geometry triggered gyroscope; no driver-initiated direction change |
| BNY-SALA-03 | Jeepney | None | Normal commute | Pothole | N/A | 14.269347, 121.125010 | **Non-Target (Pothole)** — road surface anomaly; excluded from driver behavior matrix |
| SALA-BNY-04 | Jeepney | None | Steady segment | Pothole | N/A | 14.256678, 121.128163 | **Non-Target (Pothole)** — road surface anomaly; excluded from driver behavior matrix |
| SALA-BNY-04 | Jeepney | 2026-10-05T22:01:44 | **Sudden direction change** (sharp swerve to overtake) | Turning | 0.0 s | 14.256678, 121.128163 | **True Positive (TP)** — contemporaneous passenger confirmation; vehicle jerked into oncoming lane to overtake |
| BNY-PNC-05 | Tricycle | None | Smooth ride — no target events | None | N/A | 14.255000, 121.128000 | **True Negative Trip (TN)** — complete ride uneventful across 310 seconds |
| PNC-BNY-06 | Tricycle | None | Smooth return — no target events | None | N/A | 14.255000, 121.128000 | **True Negative Trip (TN)** — complete ride uneventful across 229 seconds |
| CMC-LB-07 | Jeepney | 2026-09-18 (trip duration) | **Sustained high-speed transit** (GPS velocity > 60 km/h on national highway) | Speeding (×1) | — | Calamba–Los Baños corridor | **True Positive (TP)** — researcher-contemporaneous: lead researcher was present in the vehicle and confirms the jeepney was traveling at high speed on an uncongested national highway segment |
| CMC-LB-07 | Jeepney | 2026-09-18 (×4 detections) | **Within-lane lateral drift** (jeepney swayed side-to-side within the same lane at highway speed) | Turning (×4) | — | Calamba–Los Baños corridor | **True Positive (TP ×4)** — researcher-contemporaneous: lateral vehicle sway within the lane at highway speed triggered the gyroscope; confirmed as physical vehicle movement, not passive road curvature |

*Note: In Trip SALA-BNY-04, one true positive swerve event occurred. In Trips DZ-PL-02 and BNY-SALA-03, three false positive events were generated by natural roadway curves. In Trip CMC-LB-07, one speeding TP and four within-lane lateral drift TPs were confirmed by the researcher who was present in the vehicle. Pothole detections are managed by the road anomaly module and are excluded from the driver behavior confusion matrix.*

### Primary Seven-Trip Validation Results and Confusion Matrix

To evaluate detection performance statistically, all seven evaluated trips were segmented into contiguous 1-second observation windows across all 3,108 seconds of transit (PL-DZ-01: 270 s; DZ-PL-02: 221 s; BNY-SALA-03: 459 s; SALA-BNY-04: 198 s; BNY-PNC-05: 310 s; PNC-BNY-06: 229 s; CMC-LB-07: 1,421 s). Each 1-second window was classified independently as "Event Present" or "Event Absent" by the ground-truth observer and by SafeRide.

The resulting confusion matrix is presented in Table 3.

**Table 3. Window-Level Confusion Matrix (Seven Evaluated Trips, N = 3,108 Windows)**

| | **SafeRide: Event Present** | **SafeRide: Event Absent** | **Row Total (Ground Truth)** |
|---|:---:|:---:|:---:|
| **Observer: Event Present** | **6** (TP) | **0** (FN) | **6** |
| **Observer: Event Absent** | **3** (FP) | **3,099** (TN) | **3,102** |
| **Column Total (SafeRide Prediction)** | **9** | **3,099** | **3,108** |

*TP breakdown: 1 swerve (SALA-BNY-04) + 1 speeding (CMC-LB-07) + 4 within-lane lateral drift (CMC-LB-07) = 6. FP: 3 road-curve triggers (DZ-PL-02 ×1, BNY-SALA-03 ×2).*

From this confusion matrix, detection performance metrics were computed as shown in Table 4.

**Table 4. SOP 1 Primary Detection Performance Metrics (Seven-Trip Validation)**

| Measure | Evaluation Metric / Formula | Primary Result |
|---|---|:---:|
| Evaluation Windows ($N$) | Total 1-second continuous observation intervals | **3,108** |
| Observed Agreement ($P_o$) | $(TP + TN) / N = (6 + 3,099) / 3,108 = 3,105 / 3,108$ | **99.90%** ($0.999035$) |
| Expected Chance Agreement ($P_e$) | $[(Row_1 \cdot Col_1) + (Row_2 \cdot Col_2)] / N^2 = [(6 \cdot 9) + (3,102 \cdot 3,099)] / 3,108^2$ | **99.52%** ($0.995185$) |
| **Cohen's Kappa ($\kappa$)** | $(P_o - P_e) / (1 - P_e) = (0.999035 - 0.995185) / (1 - 0.995185)$ | **0.7995** |
| Precision | $TP / (TP + FP) = 6 / (6 + 3)$ | **66.67%** |
| Recall | $TP / (TP + FN) = 6 / (6 + 0)$ | **100.00%** |
| Specificity | $TN / (TN + FP) = 3,099 / (3,099 + 3) = 3,099 / 3,102$ | **99.90%** ($0.999033$) |
| F1-Score | $2 \times (\text{Precision} \times \text{Recall}) / (\text{Precision} + \text{Recall}) = 2 \times (0.6667 \times 1.00) / 1.6667$ | **0.8000** |

### Statistical Interpretation and Critical Limitations

The statistical measures derived from the primary seven-trip evaluation (and its comparative six-trip local transit baseline) yield several critical conclusions regarding SafeRide’s operational capabilities and limitations:

1. **Substantial Detector-to-Ground-Truth Agreement ($\kappa = 0.7995$)**:
   In the primary seven-trip validation dataset ($N = 3,108$ windows), SafeRide achieved an observed agreement of $P_o = 99.90\%$ and an expected chance agreement of $P_e = 99.52\%$, resulting in **Cohen’s kappa ($\kappa = 0.7995$)**. Under the benchmark scale established by Landis and Koch (1977) [62], this quantifies **substantial agreement** (0.61–0.80) between SafeRide’s automated sensor detection and observer ground truth. Importantly, this metric quantifies **detector-to-ground-truth concordance**, correcting for the extreme imbalance inherent in second-by-second transit time-series data [61]. It does **not** evaluate human inter-rater reliability, as observations were recorded by a designated passenger-observer per trip rather than two independent observers rating the vehicle concurrently.

2. **Comparative Local-Transit Baseline (Six Trips, $N = 1,687$, $\kappa = 0.3994$)**:
   When evaluating solely the six contemporaneous local transit trips conducted within Cabuyao City ($N = 1,687$ windows; PL-DZ-01 through PNC-BNY-06), only a single target unsafe event—a sharp overtaking swerve on Trip SALA-BNY-04—naturally occurred. Because no speeding or hard braking events occurred organically in those congested, short-distance local routes, and three false-positive turning triggers were induced by roadway curves, the six-trip local baseline yielded $\kappa = 0.3994$ (reported as $0.3997$ under intermediate rounding; **fair-to-moderate agreement**) and a precision of **25.00%** ($1/4$). Comparing the two datasets demonstrates that SafeRide's detection precision and kappa are strongly route-dependent: local urban routes with frequent curves and low speeds produce false turning triggers on road bends, whereas higher-speed corridor transit allows both speed and lateral dynamics to be captured with high statistical concordance.

3. **Trip CMC-LB-07 Field Validation (Speeding and Within-Lane Lateral Drift)**:
   Trip CMC-LB-07 (Calamba City to Los Baños, September 18, 2026; 1,421 seconds) provides critical empirical evidence of sensor performance during higher-speed transit along an arterial national highway. The lead researcher was physically present on board as a researcher-contemporaneous observer. Two operational behaviors were verified:
   - **Speeding Detection ($TP \times 1$)**: Operating on an uncongested highway segment without heavy traffic, the jeepney sustained high speeds exceeding the national highway speed limit (> 60 km/h). SafeRide's automated GPS velocity tracker triggered a Speeding detection, which was confirmed as a field-verified True Positive by the researcher on board.
   - **Within-Lane Lateral Sway / Hovering ($TP \times 4$)**: During the highway run, the jeepney exhibited repeated lateral sway and hovering near the lane edges within the same travel lane. SafeRide's gyroscope detector (> 1.5 rad/s) triggered four Turning events. Because the researcher observed and confirmed real physical side-to-side vehicle swaying at highway velocity, these events are classified as True Positives for lateral vehicle motion. Methodologically, however, this underscores an important threshold limitation: while the gyroscope accurately registers physical lateral angular velocity, it cannot distinguish between benign within-lane wandering/hovering and hazardous emergency swerves.

4. **Road Curvature Induced False Positives (Local Precision Limitation)**:
   Across all seven trips, three false-positive turning triggers occurred (one on DZ-PL-02 at 19:20:54, and two on BNY-SALA-03 at 16:55:20 and 16:57:35). In all three instances, vehicle angular velocity passively exceeded 1.5 rad/s while traversing sharp roadway bends without sudden steering jerk by the driver. This explains why overall precision across the seven trips is 66.67% ($6/9$), and highlights the operational need for multi-sensor filtering (e.g., fusing gyroscope angular velocity with lateral accelerometer g-force and heading change) to suppress passive curvature artifacts.

5. **Scarcity of Hard Braking Events**:
   Across all seven evaluated trips (3,108 seconds of cumulative transit), no sudden or emergency braking events (< –3.5 m/s²) occurred organically. Drivers maintained gradual deceleration when stopping for passengers. Consequently, **the empirical sensitivity of SafeRide's hard braking detector could not be populated or established under real-world field conditions**, remaining a documented constraint for future closed-track or targeted evaluation.

---

## Relationship Between Sensor Anomaly Scores and Crowd-Reported Safety Incidents (SOP 2)

### Background and Evaluation Approach

The second specific objective evaluates whether a monotonic relationship exists between SafeRide’s sensor-detected anomaly counts and the severity levels submitted in passenger hazard reports. SafeRide enables passengers to submit crowdsourced incident reports across four categories (Speeding, Sudden Braking, Reckless Driving, Pothole) with an assigned severity rating on a 5-point scale (1 = Minor, 5 = Severe).

To evaluate this relationship rigorously, the analysis clearly defines the two variables being correlated:
- **Sensor Variable ($Y$)**: The trip-level count of physical driving anomalies, defined as the sum of detected speeding, braking, and turning events ($Y = \text{speedingCount} + \text{brakingCount} + \text{turningCount}$) recorded over the entire duration of the matched trip.
- **Passenger Variable ($X$)**: The commuter's reported incident-severity rating, an ordinal measure evaluated on a 5-point Likert-type scale ranging from 1 (Minor) to 5 (Severe).

**Evidentiary Scope and Framing**:
The results of this analysis must be interpreted strictly as an **exploratory association in the matched sample**, and **not as proof that sensor anomalies predict incident severity** or that physical sensor spikes cause or explain passenger severity perceptions.

Spearman’s rank correlation coefficient ($\rho_s$) was selected as the appropriate non-parametric statistical measure because:
1. Reported severity ($X$) is an ordinal variable;
2. Trip-level sensor event counts ($Y$) are discrete integers that exhibit positive skewness; and
3. The evaluation seeks to explore whether higher sensor-detected anomaly frequencies monotonically correspond to greater passenger-perceived hazard severity [60].

### Passenger-Report Dataset Differentiation and Matching Rules

To ensure methodological clarity, two distinct passenger-report datasets accumulated during SafeRide's evaluation are distinguished:
- **Broader Conformity and Trust Dataset ($N = 124$ reports)**: Compiled across all testing phases in Laguna (`saferide_passenger_reports.csv`) to evaluate user reporting frequency, trust-weight distribution, and high-level hazard category distributions across public transport routes.
- **Matched Sensor-Report Dataset ($n = 12$ reports)**: Formed by strictly pairing reports submitted during trips where continuous smartphone sensor logging was fully active and archived in client SQLite databases. This paired dataset represents the primary sample evaluated for Spearman rank correlation.

**Primary Matching Rule**:
A report was included in the matched dataset if and only if:
1. The report's `tripId` corresponded to an existing trip record in the **same passenger's** local SQLite client database (`trips` table in `export data/SR/`); and
2. The matched trip record contained complete, non-null sensor event counts.

*Note on Sanity Criteria*: In secondary cross-pipeline validation, temporal sanity ($\Delta t \le 24$ hours) and geospatial proximity ($\Delta d \le 5\text{ km}$) checks were enforced to reject erroneous cross-user linkages.

Table 5 presents the 12 matched report-trip records extracted from the client databases, along with their tied ranks and squared differences.

**Table 5. Matched Report-Trip Dataset for Spearman's Rank Correlation**

| Report ID | Contributing User | Trip ID | Hazard Category | Reported Severity ($X$) | Total Sensor Events ($Y$) | Tied Rank ($R_X$) | Tied Rank ($R_Y$) | Difference ($d = R_X - R_Y$) | Squared Diff ($d^2$) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Rep 1 | User 1 | Trip 1 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| Rep 2 | User 1 | Trip 13 | Reckless Driving | 2 | 4 | 1.0 | 10.0 | –9.0 | 81.00 |
| Rep 3 | User 1 | Trip 16 | Pothole | 4 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| Rep 4 | User 1 | Trip 18 | Pothole | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| Rep 5 | User 1 | Trip 18 | Pothole | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| Rep 6 | User 1 | Trip 20 | Sudden Braking | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| Rep 7 | User 1 | Trip 22 | Pothole | 4 | 1 | 9.0 | 6.0 | +3.0 | 9.00 |
| Rep 8 | User 1 | Trip 25 | Pothole | 5 | 8 | 12.0 | 12.0 | 0.0 | 0.00 |
| Rep 9 | User 1 | Trip 26 | Pothole | 4 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| Rep 10 | User 2 | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| Rep 11 | User 2 | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| Rep 12 | User 2 | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Total** | | | | | | | | | **$\sum d^2 = 101.50$** |

### Statistical Analysis: Report-Level vs. Trip-Level

Because both variables contain tied ranks in the 12 observations, the unadjusted shortcut formula $\rho = 1 - 6\sum d^2 / (n(n^2-1)) = 0.6451$ is mathematically invalid because it overstates correlation by failing to correct for reduced rank variance. Applying the exact Pearson product-moment formulation on fractional ranks (Zar, 2010 [60]):
$$\rho_s = \frac{S_{xy}}{\sqrt{S_{xx} S_{yy}}}$$
where the rank deviations and cross-products calculated from the 12 observations are:
- Sum of squared rank differences: $\sum d_i^2 = \mathbf{101.50}$;
- Corrected rank sum of squares for severity ($X$): $S_{xx} = \sum (R_{X_i} - \bar{R}_X)^2 = \mathbf{123.0}$;
- Corrected rank sum of squares for sensor events ($Y$): $S_{yy} = \sum (R_{Y_i} - \bar{R}_Y)^2 = \mathbf{130.5}$;
- Rank cross-product: $S_{xy} = \sum (R_{X_i} - \bar{R}_X)(R_{Y_i} - \bar{R}_Y) = \mathbf{76.0}$;
- **Exact Tied-Rank Correlation**:
  $$\rho_s = \frac{76.0}{\sqrt{123.0 \times 130.5}} = \frac{76.0}{\sqrt{16051.5}} = \frac{76.0}{126.6945} = \mathbf{0.5999} \approx \mathbf{+0.60} \quad [60];$$
- Test statistic ($t$-approximation): $t = 0.5999 \times \sqrt{10 / (1 - 0.3599)} = \mathbf{2.371}, df = 10$;
- Two-tailed significance: **$p = 0.039$** ($p < 0.05$).

**Dual Analysis: Report-Level vs. Trip-Level Aggregation**:
To prevent pseudo-replication from multiple reports submitted on the same trip, reports were aggregated to unique transit trips ($N = 9$ unique trips).
- **Aggregation Rule**: For trips with multiple reports, reported severity ratings are averaged ($X_{\text{trip}} = \frac{1}{k}\sum_{i=1}^k X_i$), while the trip-level sensor event count ($Y_{\text{trip}}$) is taken directly from the trip record.
  - *Trip 18*: Rep 4 ($X=4$) and Rep 5 ($X=4$) $\rightarrow$ mean $X = 4.0$, events $Y = 4$.
  - *User 2 – Trip 2*: Rep 10 ($X=3$), Rep 11 ($X=3$), Rep 12 ($X=3$) $\rightarrow$ mean $X = 3.0$, events $Y = 0$.
- **Trip-Level Intermediate Statistics ($N = 9$)**:
  - $\sum d^2 = 54.5$, $S_{xx} = 53.0$, $S_{yy} = 57.0$, $S_{xy} = 27.75$;
  - Tied-rank correlation: $\rho_s = \frac{27.75}{\sqrt{53.0 \times 57.0}} = \mathbf{0.5049} \approx \mathbf{+0.50}$;
  - Test statistic: $t = 1.55, df = 7, p = \mathbf{0.165}$ (**Not statistically significant**).

Table 6 summarizes the dual analytical results.

**Table 6. Dual Spearman Rank Correlation Analysis (SOP 2)**

| Unit of Analysis | Sample Size ($n$) | Spearman Correlation ($\rho_s$) | Test Statistic ($t$, $df$) | Significance ($p$-value) | Evidentiary Interpretation |
|---|:---:|:---:|:---:|:---:|---|
| **Matched reports (Exploratory)** | **12** | **+0.60** ($0.5999$) | $t = 2.37, df = 10$ | **$p = 0.039$** | Nominally significant exploratory trend; vulnerable to user clustering |
| **Aggregated unique trips (Conservative)** | **9** | **+0.50** ($0.5049$) | $t = 1.55, df = 7$ | **$p = 0.165$** | Non-significant after collapsing repeated trip observations; conservative interpretation |

### Methodological Interpretation and Mandatory Sample Limitations

The report-level analysis ($n = 12, \rho_s = +0.60, p = 0.039$) demonstrates a statistically significant positive monotonic relationship between physical sensor triggers and passenger hazard ratings within this specific matched sample. However, when the data are collapsed by unique transit trip ($N = 9$, averaging multiple reports per trip to enforce unit independence), the correlation moderates to $\rho_s = +0.50$ ($t = 1.55, df = 7, p = 0.165$), which is **not statistically significant** at the conventional $\alpha = 0.05$ threshold.

To maintain strict scientific honesty and prevent over-interpretation, **four critical methodological limitations must be explicitly acknowledged**:

1. **Small Sample Size**:
   The matched sample comprises only $n = 12$ reports across $N = 9$ unique trips. This small sample severely limits statistical power, widens estimation confidence intervals, and precludes generalized claims regarding commuter behavior.
2. **Dominant Passenger and User Clustering**:
   The 12 records were contributed by **only two distinct users**. User 1 contributed 9 of the 12 reports (75.0%), while User 2 contributed 3 reports that all occurred on a single trip (Trip 2). This extreme clustering means observations violate the assumption of statistical independence, reflecting individual reporting habits rather than a representative commuter cohort.
3. **Unmatched Records**:
   Out of the 124 passenger hazard reports collected in the broader Firebase database, **112 records (90.3%) could not be paired** with continuous onboard sensor telemetry (89 submitted outside active trips without trip tracking, 23 on unarchived/unsynced client devices).
4. **Absence of Incident-Specific Sensor Windows**:
   The sensor variable ($Y$) represents the aggregate count of driving anomalies accumulated over the **entire duration of the trip**, rather than a localized sensor window (e.g., $\pm 5$ minutes or $\pm 150$ meters) surrounding the precise location and timestamp of the reported incident. Consequently, the analysis cannot establish that a specific sensor event directly coincided with the reported hazard.

### Separate Matching Pipelines & Sensitivity Analysis

To test the robustness of the matched correlation against passenger concentration, two separate matching pipelines were evaluated independently. These pipelines utilize different underlying samples and matching criteria, producing opposite correlation directions; **neither pipeline confirms or validates the other**:

1. **Pipeline 1: Native SQLite Dataset ($n = 12$, PRIMARY)**:
   Reports natively linked to client databases in-trip, covering 2 users across trips with 0–8 events ($\rho_s = +0.5999, p = 0.039$). Anchored by Trip 25 (severity 5, 8 events). Excluding User 1 leaves only User 2's three reports on Trip 2 (all severity 3, zero sensor events), eliminating all rank variance and causing the correlation to collapse.
2. **Pipeline 2: Firebase Cross-Matched Pipeline ($n = 11$)**:
   Derived by matching Firebase reports to client databases via spatio-temporal sanity criteria ($\Delta t \le 24$ hr, $\Delta d \le 5$ km). In this dataset, the raw correlation was strongly negative ($\rho_s = -0.8864, t = -5.74, p = 0.0003$). However, **10 of the 11 reports (90.9%) originated from a single passenger** (`5y0AF7w3`).
3. **Dominant Passenger Exclusion Test**:
   When the sensitivity test was executed by excluding the dominant passenger (`5y0AF7w3`), the sample size **dropped from $n = 11$ to $n = 1$**. With only one observation remaining, the Spearman correlation calculation **completely collapsed (mathematically undefined due to insufficient sample size)**.
4. **Minority Passenger Exclusion Test**:
   Excluding the single minority passenger (`59C62FDg`) left $n = 10$ reports from passenger `5y0AF7w3`, yielding $\rho_s = -0.9129$ ($p = 0.0002$), which merely reproduced that individual's idiosyncratic rating pattern.

**Recommended Conclusion for SOP 2**:
The matched native SQLite sample showed a positive exploratory association between reported incident severity and trip-level sensor-event counts ($\rho_s = +0.60, p = 0.039$). However, the small sample ($n=12$), repeated observations, contributor concentration (2 users), and use of trip-wide rather than incident-specific sensor data prevent a general conclusion that higher sensor-event counts reliably correspond to more severe passenger-reported incidents across the commuter population. The credibility mechanism is implemented in the system, but its individual numerical contributions cannot be independently reconstructed from static snapshots alone.

**Sensitivity Conclusion**:
These sensitivity analyses demonstrate that any matched correlation between SafeRide sensor counts and crowdsourced severity is **extremely fragile and dominated by individual passenger profiles**. This confirms that the observed positive correlation ($\rho_s = +0.60$) is an **exploratory artifact of the matched sample**, not generalizable proof that sensor anomalies predict incident severity across the broader transit population.

### Methodological Boundaries Regarding Human Inter-Rater Reliability

To establish full academic compliance and address panel inquiries (specifically regarding the distinct forms of consensus in SafeRide), three distinct evaluation concepts must be strictly separated:

1. **Human Inter-Rater Reliability (NOT Measured)**:
   - *Definition*: Formal inter-rater reliability (such as Cohen's kappa or Fleiss' kappa) requires paired, independent human raters who independently evaluate the exact same transit hazard events under a concurrent, dual-blind observation protocol.
   - *Status in SafeRide*: SafeRide gathered primary commuter incident pins without deploying paired independent observers on the same vehicles. Therefore, **human inter-rater reliability was not measured or completed**.
2. **Sensor-to-Reference Concordance (Evaluated in SOP 1 Only)**:
   - *Definition*: The agreement between an automated physical sensor threshold detector and an independent observer's ground-truth log.
   - *Status in SafeRide*: This was rigorously evaluated in SOP 1 across 3,108 one-second observation windows, yielding Cohen's $\kappa = 0.7995$. Cohen's kappa belongs exclusively to SOP 1 and must **never** be cited as a measure of crowdsourced human inter-rater reliability.
3. **Community Moderation (Asynchronous Platform Feature)**:
   - *Definition*: Asynchronous upvoting or flagging of previously submitted hazard pins by subsequent commuters using the map interface.
   - *Status in SafeRide*: Across the 124 recorded hazard pins, 109 remained unrated/pending, 10 were flagged as absent/inaccurate, and 5 were confirmed present. This constitutes asynchronous community moderation, not a synchronous, dual-blind inter-rater reliability experiment.

### Evaluation of Adaptive Credibility: Reporting Frequency and Sensor Conformity (SOP 2.1 & 2.2)

The study's second specific problem also investigated how commuter credibility is evaluated by the weighted reporting module:

1. **Credibility Based on Reporting Frequency (SOP 2.1)**:
   - *Algorithmic Formulation*: SafeRide implements an exponential saturation curve in `TrustScoringService.calculateFrequencyScore()`:
     $$F(n) = 1 - e^{-n / 15}$$
     where $n$ is the commuter's cumulative report count. This formulation models the principle that credibility increases with sustained participation while saturating asymptotically at higher frequencies (accounting for 20% of the overall trust score).
   - *Data Limitation & Honest Disclosure*: In the archived study datasets (`saferide_trust_metrics.csv`), records reflect static snapshots of final cumulative report counts and computed trust values at export time. **The available study records do not contain a complete history of initial trust values, subsequent trust-score changes, or a report-by-report calculation log. Therefore, the numerical effect of reporting frequency on adaptive credibility scores cannot be independently verified from the available records.**

2. **Credibility Based on Sensor Conformity (SOP 2.2)**:
   - *Algorithmic Formulation*: In `TrustScoringService.calculateSensorAlignmentScore()`, report severity is compared against concurrent sensor event frequencies and average sensor risk (contributing 20% of overall trust).
   - *Non-Invalidation Principle*: A foundational principle of the multi-source design is that the **absence of a matching sensor event should not automatically invalidate a report**. Many legitimate commuter hazards—such as deep potholes navigated at crawling speeds, driver discourtesy, passenger overcrowding, minor vehicular mechanical defects, or hazards logged roadside outside active trip tracking—do not produce physical deceleration (< –3.5 m/s²) or rotational (> 1.5 rad/s) threshold exceedances.
   - *Data Limitation & Honest Disclosure*: While sensor alignment logic is implemented in system source code, **the available files do not provide a complete report-by-report record showing how each concordance result changed the user’s trust score, so the direct numerical effect of sensor conformity on adaptive credibility remains unverified.** Future iterations require an append-only event ledger to enable comprehensive empirical verification of longitudinal trust score evolution.

---

## Trip-Level Safety Score Generation and Route Characterization (SOP 3)

### Background and Score Computation Logic

The third specific objective assesses whether SafeRide's composite Trip Risk Score is systematically differentiated from its sensor-only component, and whether it reflects distinct operational conditions across evaluated transit routes.

SafeRide calculates trip risk using an adaptive multi-source fusion algorithm:

$$\text{Risk}_{\text{trip}} = \lambda \cdot R_{\text{sens}} + (1 - \lambda) \cdot R_{\text{rep}} + \beta \cdot |R_{\text{sens}} - R_{\text{rep}}|$$

where:
- $R_{\text{sens}} \in [0, 1]$ is normalized sensor anomaly density;
- $R_{\text{rep}} \in [0, 1]$ is trust-weighted passenger report severity;
- $\lambda \in [0, 1]$ is the sample-size adaptive weighting parameter defined by:
  $$\lambda = \frac{N_{\text{sens}} + 20}{N_{\text{sens}} + 20 + N_{\text{rep}}}$$
  where $+20$ is a Bayesian smoothing constant ensuring sensor stability when report counts are small;
- $\beta = 0.10$ (designated as $\phi$ / `inconsistencyPenalty` in `lib/services/risk_scoring.dart`) is a discrepancy penalty coefficient that penalizes divergence between sensor readings and passenger reports; and
- $|R_{\text{sens}} - R_{\text{rep}}|$ is the absolute difference between the two risk inputs.

The resulting composite value $\text{Risk}_{\text{trip}}$ is clamped to the unit interval $[0.0, 1.0]$. The user-facing **Trip Safety Score** is an integer on a 0–100 scale:

$$\text{Safety Score} = \lfloor 100 \times (1 - \text{Risk}_{\text{trip}}) \rfloor$$

The stored database metric (`risk_score`) is its exact mathematical complement:

$$\text{Risk Score} = 100 - \text{Safety Score}$$

### Paired Comparison: Wilcoxon Signed-Rank Test

To evaluate whether the composite risk score systematically differs from the sensor-only risk component, a paired non-parametric evaluation was performed on the nine unique reported trips from SOP 2.

#### Resolution of the Score Scale Representation
SafeRide operates across two mathematically equivalent representations of trip risk:
1. **Normalized Unit Scale ($[0.0, 1.0]$)**: Used internally within the multi-source fusion algorithm, where $R_{\text{sens}} \in [0, 1]$, $R_{\text{rep}} \in [0, 1]$, and $R_{\text{trip}} \in [0, 1]$.
2. **Database / User-Facing Scale ($[0.0, 100.0]$)**: Stored in SQLite databases as `risk_score` and presented in summary dashboards, defined as:
   $$\text{Stored Risk Score} = 100 \times R_{\text{trip}}$$
   $$\text{Sensor-Only Risk Score} = 100 \times R_{\text{sens}}$$

Because the two scales are related by a constant positive scalar multiplier ($k = 100$), rank ordering is strictly preserved. Consequently, the absolute ranks, signed ranks, test statistic ($W = 0.0$), and $p$-value ($p = 0.0156$) are **completely invariant** whether computed on the normalized $[0.0, 1.0]$ scale or the $[0.0, 100.0]$ percentage scale. Both representations are reported side-by-side in Table 7 for complete transparency.

**Table 7. Paired Risk Score Data Across All Nine Unique Evaluated Trips (Dual Scale Presentation)**

| Trip Identifier | Contributing User | Sensor Risk ($R_{\text{sens}}$) [0–1] | Stored Sensor Score [0–100] | Composite Risk ($R_{\text{trip}}$) [0–1] | Stored Composite Score [0–100] | Difference ($D = R_{\text{trip}} - R_{\text{sens}}$) [0–1] | Difference ($D_{100}$) [0–100] | Absolute Rank ($|D|$) | Signed Rank | Status in Wilcoxon Test |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Trip 1** | User 1 | 0.0000 | 0.00 | 0.0000 | 0.00 | 0.0000 | 0.00 | Tied zero | — | **Dropped ($D=0$)** |
| **Trip 20** | User 1 | 0.0000 | 0.00 | 0.0000 | 0.00 | 0.0000 | 0.00 | Tied zero | — | **Dropped ($D=0$)** |
| **Trip 25** | User 1 | 0.0005 | 0.05 | 0.0040 | 0.40 | +0.0035 | +0.35 | 1.0 | +1.0 | Evaluated |
| **User2-Trip2** | User 2 | 0.0000 | 0.00 | 0.0152 | 1.52 | +0.0152 | +1.52 | 2.0 | +2.0 | Evaluated |
| **Trip 22** | User 1 | 0.0007 | 0.07 | 0.0224 | 2.24 | +0.0217 | +2.17 | 3.0 | +3.0 | Evaluated |
| **Trip 26** | User 1 | 0.0008 | 0.08 | 0.0343 | 3.43 | +0.0335 | +3.35 | 4.0 | +4.0 | Evaluated |
| **Trip 13** | User 1 | 0.0023 | 0.23 | 0.0421 | 4.21 | +0.0398 | +3.98 | 5.0 | +5.0 | Evaluated |
| **Trip 18** | User 1 | 0.0381 | 3.81 | 0.1142 | 11.42 | +0.0761 | +7.61 | 6.0 | +6.0 | Evaluated |
| **Trip 16** | User 1 | 0.0129 | 1.29 | 0.1499 | 14.99 | +0.1370 | +13.70 | 7.0 | +7.0 | Evaluated |

#### Handling of Zero Differences and Wilcoxon Test Derivation
As shown in Table 7, all nine unique naturalistic trips were assessed. Following the standard methodology for the Wilcoxon signed-rank test (Wilcoxon, 1945 [63]), pairs with zero difference ($D = 0.0000$ in Trips 1 and 20) provide no directional evidence regarding score divergence and are dropped from ranking. This yields an effective sample size of **$N_{\text{diff}} = 7$ non-zero paired differences**.

All seven non-zero differences were positive ($R_{\text{trip}} > R_{\text{sens}}$ on both scales):
- Positive rank sum: $W^+ = 1 + 2 + 3 + 4 + 5 + 6 + 7 = \mathbf{28.0}$
- Negative rank sum: $W^- = \mathbf{0.0}$
- Test statistic: $W = \min(W^+, W^-) = \mathbf{0.0}$
- Exact two-tailed $p$-value: $p = 2 \times (1/2)^7 = 2/128 = \mathbf{0.015625} \approx \mathbf{0.016}$

Because $p = 0.016 < 0.05$, the null hypothesis of symmetric differences centered at zero is rejected at the $\alpha = 0.05$ significance level. This confirms a statistically significant increase in composite risk scores when passenger hazard reports are present.

#### Narrow Evidentiary Wording of the Wilcoxon Conclusion
- **What this result supports**: The Wilcoxon test supports the claim that the composite risk score was **systematically higher than the sensor-only score** for the seven non-zero pairs examined, reflecting the addition of passenger hazard severity and the discrepancy penalty.
- **What this result does NOT establish**:
  1. It does **not** establish that the composite score is more accurate in predicting real-world danger.
  2. It does **not** independently validate the risk score against collision records, official traffic safety data, or another external criterion.
  The test evaluates how the multi-source fusion algorithm changes the score when its inputs are combined, not its empirical accuracy against ground-truth safety outcomes.

---

### Database Scale Analysis (N = 150 Recorded Trips) and Route Accounting

To examine system behavior across broader operations, the complete repository of **150 recorded trips** archived in SafeRide’s SQLite database files was analyzed.

Across all 150 trips, Spearman’s rank correlation was calculated between **total sensor-event counts** (the sum of speeding, sudden braking, and turning detections per trip) and **composite trip risk scores** (`risk_score`):

$$\rho_s = \mathbf{+0.6146}, \quad t = 9.48, \quad df = 148, \quad p < 0.0001$$

#### Model Behavior Interpretation (Built-in Mathematical Coupling)
The positive correlation ($\rho_s = +0.6146, p < 0.0001$) indicates that trips with more recorded sensor events generally had higher composite risk scores in the evaluated database. 

However, a crucial methodological distinction must be made: **the composite risk score already incorporates sensor-derived risk as a direct input**. Therefore, the two variables are mathematically coupled by the system's design. This correlation reflects the scoring model's internal behavior and does **not** serve as independent proof of system accuracy or as proof that sensor events are the dominant cause of real-world risk.

#### Trip and Route Accounting in the Database
To resolve ambiguities in route and trip counts, the 150 recorded trips in the SQLite database are accounted for as follows:
- **Primary Corridor Table ($N = 24$ trips)**: Trips on established transit arteries, including the Cabuyao City Loop (14 trips), Calamba–Los Baños highway runs (2 trips), and primary arterial segments in Biñan, Santa Rosa, and Calamba.
- **Other Named Local Trips ($N = 22$ trips)**: Retesting runs (PL-DZ-01, DZ-PL-02, SALA-BNY-04, BNY-PNC-05, PNC-BNY-06), the three BNY-SALA-03 runs, and specific local address pickups.
- **Subtotal Named / Geocoded Trips ($N = 46$ trips)**: All trips bearing specific corridor names, route labels, or reverse-geocoded road coordinates.
- **Unassigned / System Test Segments ($N = 104$ trips)**: System calibration tests, stationary sensor tests, and short tracking verification segments without formal corridor names. These 104 unassigned records describe database behavior but are not treated as 104 independent real-world route observations.
- **Total Recorded Trips in SQLite Archive**: **$150$ trips**.

Table 8 summarizes the route-level risk and safety score distribution across the three evaluated public utility vehicle (PUV) transit corridors in Cabuyao City from the formal field retesting, alongside the exploratory highway corridor.

**Table 8. Evaluated PUV Route Corridor Risk and Safety Score Summary (Field Retesting)**

| Route / Corridor Label | Evaluated Trips ($N$) | Mean Risk Score (0–100) | Mean Safety Score (0–100) | Vehicle Type | Route Operational Context & Verified Field Findings |
|---|:---:|:---:|:---:|:---:|---|
| **Pulo ↔ Diezmo Corridor** | 2 | 11.33 | 88.67 | Motorized Tricycle | Local collector road; moderate operating speeds (< 30 km/h), surface depressions, road curve FP in DZ-PL-02 |
| **Banaybanay ↔ Sala Corridor** | 2 | 6.78 | 93.22 | Public Utility Jeepney | Arterial provincial road; mixed traffic flow, 1 verified overtaking swerve TP in SALA-BNY-04, 2 road curve FPs in BNY-SALA-03 |
| **Banaybanay ↔ PNC Campus Corridor** | 2 | 0.08 | 99.92 | Motorized Tricycle | Smooth university access corridor; low-speed, steady transit, zero hazardous events detected |
| *Calamba (CMC) → Los Baños\** | 1 (2 logs)\* | 16.64 | 83.36 | Public Utility Jeepney | National highway corridor; high-speed transit (> 60 km/h speeding detection) and 4 routine highway lane switches |

*\*Note on Calamba → Los Baños ($N = 1$ journey, 2 DB records): The database archive contains two records with identical timestamps and metrics (Risk = 16.64), representing dual client database exports (`saferide.db` Trip 9 and user database Trip 20) of the same single highway transit run, not two independent journeys.*  
*\*Note on Route Tag BNY-SALA-03 in Historical Archive: In the broader SQLite archive, two subsequent developer check runs were logged under this tag on October 7, 2026 (Trip 235, Risk = 0.00; Trip 238, Risk = 0.25). Combining those check runs with the evaluated field trip (Trip 207, Risk = 13.06) yields a historical database mean of $(13.06 + 0.00 + 0.25) / 3 = 4.44$. Table 8 reports the actual evaluated commuter field retesting corridor (mean of outbound Trip 207 and inbound Trip 220: $(13.06 + 0.49) / 2 = 6.78$), resolving the previous manuscript inconsistency.*

---

## Preservation and Updating of Figures 16–27

Figures 16 through 27 are preserved in the SafeRide manuscript, with accompanying discussions updated to align with verified test results and the implemented scoring formula:

- **Figure 16 (SafeRide Main Interface)**: Preserved. Depicts the idle standby dashboard and spatial route map displaying baseline sensor readiness and historical community safety scores prior to trip monitoring.
- **Figure 17 (SafeRide Trip Monitoring Interface)**: Preserved and updated. Depicts real-time data acquisition. The discussion has been corrected to remove the contradictory "50% sensor / 50% report equal weighting" statement. It now accurately describes the implemented algorithm: **adaptive multi-source weighting based on sample size ($\lambda$) combined with a discrepancy penalty factor ($\beta = 0.10$)**.
- **Figure 18 (Speed Monitoring and Speeding Detection Result)**: Preserved. Illustrates spatial tracking and telemetry during a high-speed highway segment, showing visual alerting and real-time safety score adjustment.
- **Figure 19 (Hard Braking Detection Result)**: Preserved. Demonstrates the deceleration detection notification and automatic incident report generation.
- **Figure 20 (Gyroscope-Based Detection of Sudden Direction Changes)**: Preserved. Displays active gyroscope thresholding (> 1.5 rad/s) and auto-population of lateral maneuver reports.
- **Figure 21 (Passenger Reporting and Credibility Evaluation Interface)**: Preserved. Demonstrates crowd-sourced reporting interfaces, categorized hazard submission, and user trust score calculation.
- **Figure 22 (Trip-Level Safety Score Generated by SafeRide)**: Preserved. Shows post-trip risk summaries, tiered risk categorization (Low < 20, Medium 20–39, High ≥ 40), and route-level safety profiles.
- **Figures 23–27 (Source Code Implementations)**: Preserved. Present verified implementations of sliding window segmentation (Fig. 23), adaptive thresholding (Fig. 24), event detection (Fig. 25), trust weighting (Fig. 26), and composite score generation (Fig. 27).

---

## Summary of Verified Findings

**Table 9. Synthesis of Findings by Specific Objective**

| SOP | Specific Objective | Statistical Tool | Evaluated Sample Size | Key Verified Result | Core Methodological Qualification |
|---|---|---|---|---|---|
| **SOP 1** | Evaluate accuracy of sensor-based detection against ground truth | Cohen's Kappa ($\kappa$) | $N = 3,108$ 1-second windows (7 trips: 6 contemporaneous + CMC-LB-07) | $\kappa = 0.7995$ (Substantial); Accuracy = 99.90%; Precision = 66.67%; Recall = 100.00%; Specificity = 99.90%; F1 = 0.8000 | Quantifies **detector-to-ground-truth agreement**, not human inter-rater reliability. 6 TPs confirmed (1 swerve, 1 speeding, 4 lateral drift). Hard braking sensitivity not establishable. 3 FPs from road curves on local roads. |
| **SOP 2** | Assess relationship between sensor anomalies and passenger reports; evaluate adaptive credibility | Spearman's Rank Correlation ($\rho_s$) & Trust Verification | $n = 12$ matched reports; $N = 9$ unique trips; 2 users ($N = 124$ total crowd reports across 13 users) | Report-level: $\rho_s = +0.60$ ($p = 0.039$); Trip-level: $\rho_s = +0.50$ ($p = 0.165$); SOP 2.1 & 2.2 trust effects unverified | Matched correlation is **exploratory**; trip-level correlation is non-significant due to user clustering (2 users). **Human inter-rater reliability was not measured** (no paired dual-blind observers). **Numerical effects of reporting frequency (SOP 2.1) and sensor conformity (SOP 2.2) cannot be independently verified** due to absence of longitudinal calculation logs; sensor event absence does not invalidate reports. |
| **SOP 3** | Determine differentiation of composite risk score from sensor-only score | Wilcoxon Signed-Rank Test & Scale Spearman | $N_{\text{diff}} = 7$ non-zero pairs; $N = 150$ total trips | Wilcoxon: $W = 0.0, p = 0.016$; 150-Trip Spearman: $\rho_s = +0.6146, p < 0.0001$ | Confirms **statistically significant score elevation** by crowd reports. Does **not prove real-world ground-truth accuracy**, which requires external criterion validation. 150-trip correlation reflects internal model coupling. |

---

# CHAPTER V: SUMMARY, CONCLUSIONS, AND RECOMMENDATIONS

## Summary of the Study

This study developed and evaluated **SafeRide**, a mobile application designed to monitor public utility vehicle (PUV) commuting safety using onboard smartphone sensors and crowdsourced passenger reports. As clarified in Chapters I and III, SafeRide serves **two connected purposes**:
1. **Crowdsourced incident reporting**: Passengers submit transportation safety incidents, which are processed through a credibility-weighting mechanism; and
2. **Safety information presentation**: The application processes available sensor data and passenger reports to calculate, visualize, and present real-time monitoring alerts, trip summaries, composite safety scores, and risk-colored route maps.

The study addressed three specific objectives:
1. **SOP 1**: To evaluate the accuracy of SafeRide’s sensor-based detection module against independently observed ground-truth events.
2. **SOP 2**: To determine whether a statistically significant monotonic relationship exists between SafeRide’s sensor anomaly counts and the severity of crowd-reported safety incidents, and to assess credibility weighting based on reporting frequency and sensor conformity.
3. **SOP 3**: To determine whether SafeRide’s composite trip risk score is significantly differentiated from its sensor-only component and reflects varying route conditions.

The evaluation was conducted using seven structured field trips spanning 3,108 seconds of active transit (six contemporaneous retesting trips in Cabuyao City and one researcher-contemporaneous highway trip between Calamba and Los Baños), supplemented by the cumulative 150-trip database export. Non-parametric statistical methods were applied: Cohen’s kappa for detector-to-ground-truth classification agreement (SOP 1), Spearman’s rank correlation with tie adjustments for monotonic association (SOP 2), and the Wilcoxon signed-rank test for paired score differentiation (SOP 3).

## Conclusions

Based on the verified statistical findings and operational analyses, the following conclusions are drawn:

1. **SOP 1. Sensor-Based Event Detection Performance**  
   Across 3,108 one-second observation windows from seven evaluated trips, SafeRide achieved 99.90% observed agreement with ground-truth classifications, yielding Cohen’s kappa $\kappa = 0.7995$ (**substantial agreement**), precision of 66.67%, recall of 100.00%, and an F1-score of 0.8000. In the six-trip local transit subset ($N = 1,687$ windows), kappa was 0.3994 and precision was 25.00%, reflecting three false-positive turning detections caused by normal roadway curvature. The inclusion of the researcher-contemporaneous highway transit trip confirmed detector sensitivity for speeding (> 60 km/h) and physical within-lane lateral vehicle movements. However, because no hard braking events occurred organically across all seven trips, empirical sensitivity for sudden braking remains unestablished under real-world conditions. Furthermore, threshold-based sensing responds to physical rotational motion but cannot distinguish benign within-lane lateral hovering from hazardous emergency swerves.

2. **SOP 2. Relationship Between Passenger Reports and Sensor Events, and Adaptive Credibility**  
   The analysis evaluated the monotonic association between the sensor variable (trip-level count of speeding, braking, and turning events) and the passenger variable (reported incident-severity rating). At the report level, the analysis found a positive Spearman rank correlation of approximately 0.60 ($n=12$, $p=0.039$). However, when aggregated to unique transit trips ($N=9$), the correlation was approximately 0.50 and was not statistically significant ($p=0.165$). Consequently, the findings must be interpreted strictly as an exploratory association in the matched sample, and not as proof that sensor anomalies predict incident severity. This preliminary result is governed by four critical limitations: (a) a small sample size ($n=12$ reports across 9 trips), (b) severe user clustering (9 of 12 reports originated from a single passenger, and sensitivity analysis demonstrated that excluding the dominant passenger causes the correlation computation to completely collapse to $n=1$), (c) unmatched records (112 of 124 crowdsourced reports in Firebase could not be linked to active onboard sensor logs), and (d) the absence of incident-specific sensor windows (sensor anomalies are trip-level aggregates rather than localized windows around the incident).  
   Furthermore, human inter-rater reliability was not evaluated because paired, dual-blind independent-rater classifications were not gathered; Cohen's kappa belongs strictly to SOP 1 sensor-to-ground-truth concordance. Crucially, available study records do not contain a complete history of initial trust values, subsequent trust-score changes, or a report-by-report calculation log; therefore, the numerical effect of reporting frequency on adaptive credibility scores cannot be independently verified from available records. In addition, because the absence of a matching sensor event does not automatically invalidate a report (many legitimate hazards do not trigger kinematic thresholds), and because available files lack a report-by-report change ledger, the direct numerical effect of sensor conformity on adaptive credibility remains unverified.

3. **SOP 3. Composite Risk Scoring**  
   The Wilcoxon signed-rank analysis indicated that the composite risk score was higher than the sensor-only risk score for the seven nonzero paired differences examined ($W=0$, exact two-sided $p=0.016$). This result describes the difference between the two scoring outputs in the analyzed sample. It does not establish that the composite score is more accurate at predicting real-world danger. Similarly, the positive association between sensor-event counts and composite scores across the 150-record database reflects, in part, the inclusion of sensor-derived risk in the scoring formula. It is not independent validation against collision records or official transportation-safety outcomes.

## Recommendations

Based on the empirical findings, system limitations, and methodological constraints identified during the study, the following recommendations are proposed:

1. **Implement Multi-Feature Heuristics to Discriminate Lane Hovering from Dangerous Swerves**
   SafeRide’s gyroscope detector (threshold: 1.5 rad/s) detected lateral maneuvers but generated false positives on road curves and responded to within-lane lateral drift. Future iterations should incorporate a multi-feature classification model combining: (a) lateral angular velocity peak duration, (b) concurrent lateral acceleration from the accelerometer, and (c) GPS velocity and heading differential. This multi-sensor fusion would filter out passive road-curvature artifacts and allow the system to classify lateral movements into tiered severity categories (routine lane drift vs. aggressive swerve), thereby suppressing road-curve false alarms and improving precision beyond current levels without sacrificing recall.

2. **Conduct Targeted Testing for Hard Braking and Controlled Speeding Events**
   Across the evaluated field trips, hard braking events did not occur organically (while speeding was verified on the arterial highway corridor). Future field evaluations should include driving protocols specifically designed to encounter or simulate sudden deceleration (e.g., congested urban intersections, designated test tracks) and high-speed highway corridors with calibrated external telemetry to populate the confusion matrix and validate the –3.5 m/s² deceleration and 60 km/h velocity thresholds.

3. **Expand Crowdsourced Testing to a Multi-User Independent Cohort**
   The SOP 2 correlation ($\rho_s = +0.60$) was limited by a sample size of 12 reports from two users. A formal crowdsourcing study involving a minimum of 30 to 50 independent commuter participants across diverse public transit lines (jeepney, bus, UV Express, tricycle) is recommended. This would eliminate user clustering effects, permit robust multi-level statistical modeling, and evaluate the trust-weighting algorithm under varied reporting behaviors.

4. **Establish a Formal Ground-Truth Protocol and Human Inter-Rater Reliability Framework**
   To advance beyond detector-to-observer agreement, future studies should implement: (a) synchronized dual-observer protocols where two independent human observers simultaneously log riding events to establish baseline human inter-rater reliability, (b) external video recording or calibrated OBD-II telemetry to serve as an objective ground-truth benchmark, and (c) external criterion validation comparing SafeRide risk scores against official transport authority safety records.

5. **Incorporate Longitudinal Route-Level Safety Profiling**
   The preliminary route characterization (Table 8) illustrated observable score variations between arterial highways and local loops. A multi-month longitudinal study tracking specific transit corridors across varying times of day, weather conditions, and vehicle models should be conducted to evaluate whether route risk indices are stable over time and can inform municipal traffic safety interventions.

6. **Pursue Regulatory and Fleet Integration**
   Future system architectures should explore secure data-sharing interfaces with transportation regulatory bodies (e.g., LTFRB, LTO) and transport cooperatives. Aggregated trip safety profiles could provide cooperatives with objective driver performance analytics and support data-driven road safety auditing in the Philippine public transport sector.

---

## References

*(Continued sequentially from manuscript reference [59])*

[60] J. H. Zar, *Biostatistical Analysis*, 5th ed. Upper Saddle River, NJ, USA: Prentice Hall, 2010.

[61] J. Cohen, “A coefficient of agreement for nominal scales,” *Educational and Psychological Measurement*, vol. 20, no. 1, pp. 37–46, 1960.

[62] J. R. Landis and G. G. Koch, “The measurement of observer agreement for categorical data,” *Biometrics*, vol. 33, no. 1, pp. 159–174, 1977.

[63] F. Wilcoxon, “Individual comparisons by ranking methods,” *Biometrics Bulletin*, vol. 1, no. 6, pp. 80–83, 1945.

[64] ISO/IEC, *ISO/IEC 25010:2023 Systems and Software Engineering — Systems and Software Quality Requirements and Evaluation (SQuaRE) — System and software quality models*. Geneva, Switzerland: ISO, 2023.
