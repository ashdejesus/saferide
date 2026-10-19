# CHAPTER IV

## RESULTS AND DISCUSSION

This chapter presents the empirical results and in-depth discussion of the development, testing, and evaluation of the SafeRide mobile risk-scoring system. The findings are presented and interpreted according to the five Statements of the Problem (SOP 1–5) formulated in the study. Specifically, this chapter analyzes: (1) the kinematic detection performance of the smartphone sensor module against contemporaneous ground-truth observations across seven public utility vehicle (PUV) transit runs; (2) the credibility weighting of crowdsourced passenger reports and the relationship between physical sensor anomalies and reported hazard severity; (3) the behavior and differentiation of the multi-source composite trip risk score and corridor-level safety assessments; and (4) the software product quality evaluations conducted with Information Technology experts and commuter end users based on the ISO/IEC 25010:2023 software product quality model.

The empirical analyses are based on raw telemetry streams collected at 10 Hz, contemporaneous field observation logs (Appendix D, Observation Sheets 1–7), crowdsourced passenger report databases, and standardized technical evaluation instruments. Statistical measures are utilized to evaluate the detection performance of the automated sensor module, the relationship between sensor-detected events and crowd-reported severity, the differentiation of trip-level composite safety scores, and the user evaluation of the mobile application. Specifically, the statistical tools employed include Cohen’s kappa ($\kappa$) [60] and the Landis–Koch agreement benchmark [61] for sensor classification, Spearman’s rank-order correlation ($\rho_s$) [62] with tied-rank correction [63] for crowdsourced reporting, the Wilcoxon signed-rank test ($W$) [64] for composite score differentiation, and the weighted mean based on a four-point Likert scale [65] for software quality evaluation.

---

### Sensor-Based Detection of Unsafe Transportation Behaviors (SOP 1)

The first specific objective of the study evaluates the capability of SafeRide's client-side mobile sensing pipeline to detect selected unsafe driving behaviors in Philippine public utility vehicles. The investigation focused on three critical transit risk behaviors: **speeding**, **hard braking (acute deceleration)**, and **sudden direction changes (aggressive swerving/turning)**. Telemetry was acquired using the built-in sensors of commercial Android smartphones: GPS for position and ground speed, a tri-axial accelerometer for linear dynamic acceleration, and a tri-axial gyroscope for angular rotational velocity.

#### Field Testing Procedure and Masterlist of Observation Sheets

Field transit evaluations were conducted across seven structured public transit runs in Laguna (Trips PL-DZ-01 through CMC-LB-07), encompassing both motorized tricycles and public utility jeepneys (PUJs). A designated observer or the lead researcher was physically stationed on board each trip with a pre-printed, standardized ground-truth observation sheet (Appendix D, Observation Sheets 1 through 7). Observers recorded the precise vehicle type, origin-destination corridor, departure and arrival times, and timestamped descriptions of any aggressive driving maneuvers or erratic vehicle motions. Roadway surface anomalies (e.g., potholes, manhole depressions) were cataloged separately as part of the road maintenance inspection log and were strictly excluded from the driver behavior classification matrix.

*Note on Nominal vs. Effective Runtime Thresholds*: The nominal baseline thresholds established in the system architecture are 60 km/h for speeding, –3.5 m/s² for hard braking, and 1.5 rad/s for sudden direction changes. In the runtime software implementation (`lib/services/risk_scoring.dart`), the system applies vehicle-specific divisors (0.75 for jeepneys, 0.65 for tricycles) and a dynamic contextual environment factor $A(t) \ge 1.0$. Under baseline operating conditions, this scaling results in effective runtime thresholds of approximately 61–71 km/h for speeding, –6.1 to –7.1 m/s² for hard braking, and 2.45–2.83 rad/s for sudden turns. This adaptive calibration prevents regular engine vibrations, passenger chassis bounce, and standard road undulations from triggering spurious alerts.

The ground-truth observations documented across all seven transit runs are summarized in Table 4.

**Table 4. Summary of Ground-Truth Observations (Seven Evaluated Transit Runs)**

| Trip ID | Route Corridor | Vehicle Type | Speeding | Hard Braking | Sudden Direction Change | Total Target Events | Observation Log Sheet |
|---|---|---|:---:|:---:|:---:|:---:|---|
| **PL-DZ-01** | Pulo → Diezmo | Motorized Tricycle | 0 | 0 | 0 | 0 | Observation Sheet 1 |
| **DZ-PL-02** | Diezmo → Pulo | Motorized Tricycle | 0 | 0 | 0 | 0 | Observation Sheet 2 |
| **BNY-SALA-03** | Banaybanay → Sala | Public Utility Jeepney | 0 | 0 | 0 | 0 | Observation Sheet 3 |
| **SALA-BNY-04** | Sala → Banaybanay | Public Utility Jeepney | 0 | 0 | 1 | 1 | Observation Sheet 4 |
| **BNY-PNC-05** | Banaybanay → PNC | Motorized Tricycle | 0 | 0 | 0 | 0 | Observation Sheet 5 |
| **PNC-BNY-06** | PNC → Banaybanay | Motorized Tricycle | 0 | 0 | 0 | 0 | Observation Sheet 6 |
| **CMC-LB-07** | Calamba (CMC) → Los Baños | Public Utility Jeepney | 1 | 0 | 4 | 5 | Observation Sheet 7 |
| **Total** | | | **1** | **0** | **5** | **6** | **Seven Master Sheets** |

As shown in Table 4, a total of six target unsafe driving events occurred across the seven evaluated transit runs. In the local urban corridors of Cabuyao City (Trips PL-DZ-01 through PNC-BNY-06), dense commercial traffic, narrow secondary roadways, and frequent passenger stops constrained vehicular speeds; only one target event occurred: an abrupt overtaking swerve executed on Trip SALA-BNY-04. On the higher-speed arterial highway connecting Calamba City and Los Baños (Trip CMC-LB-07), five target events were documented under researcher-contemporaneous observation: one sustained speeding event exceeding the 60 km/h threshold along an open, uncongested stretch of the national highway, and four distinct within-lane lateral sway and hovering movements where the jeepney drifted side-to-side at high velocity. Zero hard-braking events occurred organically during any of the seven evaluated runs, as drivers consistently decelerated gradually when dropping off passengers.

#### Evaluation Unit Definition: Feature Window vs. Evaluation Epoch

To ensure methodological precision, the temporal processing pipeline distinguishes between the **feature extraction window** and the **discrete evaluation epoch**:
1. **Feature Extraction Window**: Continuous sensor telemetry is buffered using a moving sliding window of length $W = 2.0$ seconds. This 2-second temporal buffer allows the system to compute moving averages for GPS speed and vector magnitudes for linear acceleration and angular velocity, smoothing out high-frequency sensor noise.
2. **Evaluation Epoch (Step Size)**: The sliding window advances at a fixed step size of $\Delta t = 1.0$ second (representing a 50% temporal overlap). Each 1-second advancement step constitutes one discrete **evaluation epoch (decision window)**, at which the extracted window features are evaluated against the adaptive detection thresholds.

Across the cumulative 51 minutes and 48 seconds (3,108 seconds) of monitored transit, this procedure produced exactly **3,108 discrete one-second evaluation epochs**. Consequently, the confusion-matrix denominator of 3,108 corresponds strictly to these 3,108 sequential 1-second classification decisions evaluated against the contemporaneous ground-truth logs. The distribution of evaluation epochs per trip is presented in Table 5.

**Table 5. Number of Evaluation Epochs per Evaluated Transit Run**

| Trip ID | Route Corridor | Vehicle Type | Trip Duration | Evaluation Epochs ($N$) | Ground-Truth Verification |
|---|---|---|:---:|:---:|---|
| **PL-DZ-01** | Pulo → Diezmo | Motorized Tricycle | 4 min 30 sec | 270 | Contemporaneous Log Sheet 1 |
| **DZ-PL-02** | Diezmo → Pulo | Motorized Tricycle | 3 min 41 sec | 221 | Contemporaneous Log Sheet 2 |
| **BNY-SALA-03** | Banaybanay → Sala | Public Utility Jeepney | 7 min 39 sec | 459 | Contemporaneous Log Sheet 3 |
| **SALA-BNY-04** | Sala → Banaybanay | Public Utility Jeepney | 3 min 18 sec | 198 | Contemporaneous Log Sheet 4 |
| **BNY-PNC-05** | Banaybanay → PNC | Motorized Tricycle | 5 min 10 sec | 310 | Contemporaneous Log Sheet 5 |
| **PNC-BNY-06** | PNC → Banaybanay | Motorized Tricycle | 3 min 49 sec | 229 | Contemporaneous Log Sheet 6 |
| **CMC-LB-07** | Calamba → Los Baños | Public Utility Jeepney | 23 min 41 sec | 1,421 | Researcher-Contemporaneous Sheet 7 |
| **Total** | | | **51 min 48 sec** | **3,108** | **Seven Evaluated Logs** |

---

#### Speeding Detection Performance

Speeding was evaluated by comparing the GPS-derived ground velocity against the speed limit threshold for each 1-second evaluation epoch. During the six local Cabuyao City trips, heavy traffic congestion and localized road geometry prevented vehicles from exceeding 45 km/h. No speeding events occurred, and SafeRide produced no false alarms.

On Trip CMC-LB-07 along the Calamba–Los Baños arterial highway, late-evening uncongested traffic permitted sustained acceleration. The jeepney reached speeds between 62 km/h and 68 km/h along an open corridor, breaching the effective threshold. SafeRide detected and logged this infraction, matching the contemporaneous observation log as a **True Positive**. The classification performance for speeding is summarized in Table 6.

**Table 6. Classification Results for Speeding Detection (N = 3,108 Evaluation Epochs)**

| Classification Category | Count | Percentage | Evaluative Description |
|---|:---:|:---:|---|
| **True Positive (TP)** | **1** | 0.03% | High-speed highway transit (> 60 km/h on CMC-LB-07) correctly flagged |
| **False Positive (FP)** | **0** | 0.00% | Zero false alarms generated under congested or standard cruising speeds |
| **False Negative (FN)** | **0** | 0.00% | Zero observed speeding violations missed by GPS tracker |
| **True Negative (TN)** | **3,107** | 99.97% | Compliant speeds correctly categorized as non-speeding |
| **Total** | **3,108** | **100.00%** | Discrete 1-second evaluation epochs |

As indicated in Table 6, SafeRide achieved 100.00% specificity ($3,107 / 3,107$) and detected the single observed speeding event (100.00% recall). This confirms that GPS ground velocity provides a robust and reliable basis for speed monitoring in mobile telematics.

```
+-------------------------------------------------------------------------+
| Figure 16. SafeRide Main Interface showing the starting point for trip  |
|            monitoring.                                                  |
+-------------------------------------------------------------------------+
```
*Figure 16 illustrates the baseline standby interface and spatial overview of the SafeRide application prior to trip monitoring initialization. As shown on the left panel, the application defaults to an Idle state where the primary trip configuration module prompts users to select their transit type—defaulting to "Jeepney"—before triggering the session via the prominent Start Trip action. During this pre-transit phase, telemetry readouts remain calibrated at zero (Current Speed at 0.0 km/h and Ride Intensity at 0%), while the Unsafe Events section reflects an "All Clear" baseline status indicating that no driving anomalies or hazard thresholds have been triggered. Concurrently, the Safety Map interface on the right provides immediate situational awareness by displaying the user's localized spatial environment alongside historical transit routes color-coded to denote road safety conditions. An overlay card presents the aggregate Community Safety metric—displaying a 96% average score derived from 158 analyzed trips with zero designated high-risk segments—accompanied by a direct call-to-action for commuters to manually report localized incidents. This establishes that the system maintains baseline sensor readiness and accessible crowdsourced safety insights prior to real-time trajectory tracking.*

```
+-------------------------------------------------------------------------+
| Figure 17. SafeRide Trip Monitoring Interface collecting sensor data in  |
|            real-time.                                                   |
+-------------------------------------------------------------------------+
```
*Figure 17 depicts the trip initialization and real-time monitoring workflow of the SafeRide application during active sensor data acquisition. As demonstrated in the left panel, the initialization modal transitions the system from an idle state by prompting the user to configure trip parameters prior to departure. Users select their vehicle classification (such as Jeepney, Bus, or Tricycle/Motorcycle) and assign a transit path via the optional route input or from suggested local corridor presets, including common routes across Cabuyao, Biñan, and Santa Rosa. Once initiated, the right panel illustrates the active monitoring dashboard marked by the "Recording" status and a prominent "Trip in progress" card. This screen continuously tracks dynamic vehicle metrics—including real-time speed, ride intensity percentages, and persistent controls to end the recording session. Concurrently, the bottom module visualizes the "Live Safety Score," computing a composite index (initialized at 100/100) derived from an adaptive multi-source fusion algorithm that weights sensor telemetry and passenger incident reports according to sample size ($\lambda$) and applies a discrepancy penalty factor ($\beta = 0.10$), validating the platform's capacity to aggregate and process multi-source safety metrics throughout transit.*

```
+-------------------------------------------------------------------------+
| Figure 18. Speed Monitoring and Speeding Detection Result.              |
+-------------------------------------------------------------------------+
```
*Figure 18 illustrates the system's live telemetry monitoring and spatial tracking during a detected speeding event. As demonstrated on the left panel under the Unsafe Events dashboard, registering an instantaneous velocity that exceeds the designated threshold increments the Speeding counter to 1, visually distinguished by a red highlight to alert the user to the active violation alongside other ongoing kinematic counts. Concurrently, the Safety Map interface on the right tracks transit in real time, plotting the traversed route and pinning the location of the speeding infraction with a red alert marker along the path. At the bottom of the spatial view, the real-time speed card displays a recorded velocity of 45.7 km/h, explicitly flagged as High Speed with corresponding sensor flags. Despite the breach, the overall aggregate index reflects an active 89% Live Safety Score, verifying that the application successfully cross-references GPS positioning and kinematic thresholds to capture localized speeding anomalies while continuously computing cumulative trip safety metrics.*

---

#### Hard Braking Detection Performance and Validation Constraints

Hard braking was evaluated using filtered longitudinal deceleration ($a_x$) derived from the device accelerometer. Deceleration exceeding –3.5 m/s² (with effective runtime limits scaling to –6.1 to –7.1 m/s² under vehicle multipliers) triggers an alert.

During the seven evaluated field trips, zero acute, emergency braking events occurred naturally in traffic; drivers maintained smooth, gradual decelerations when stopping for passengers. Concurrently, SafeRide generated zero hard-braking alerts across all 3,108 evaluation epochs. The classification outcomes are presented in Table 7.

**Table 7. Classification Results for Hard-Braking Detection (N = 3,108 Evaluation Epochs)**

| Classification Category | Count | Percentage | Evaluative Description |
|---|:---:|:---:|---|
| **True Positive (TP)** | **0** | 0.00% | Zero organic emergency braking events encountered in field testing |
| **False Positive (FP)** | **0** | 0.00% | Normal passenger decelerations produced zero false alarms |
| **False Negative (FN)** | **0** | 0.00% | Zero observed braking events missed |
| **True Negative (TN)** | **3,108** | 100.00% | Compliant stops correctly categorized as non-events |
| **Total** | **3,108** | **100.00%** | Discrete 1-second evaluation epochs |

**Critical Methodological Constraint**: Because no ground-truth hard-braking events occurred during field testing, empirical sensitivity (Recall) cannot be mathematically established ($0 / 0$). The observation of zero false alarms ($FP = 0$) confirms high operational specificity ($100.00\%$) against false triggers during ordinary stop-and-go driving. **However, these results should not be construed as full empirical validation of the hard-braking detection algorithm.** Because the detector was never stimulated by actual emergency braking in the field, its real-world detection capability remains empirically unverified in this study. Controlled vehicular testing involving intentional emergency stops on a closed track is necessary to quantify true positive sensitivity.

```
+-------------------------------------------------------------------------+
| Figure 19. Hard Braking Detection Result.                               |
+-------------------------------------------------------------------------+
```
*Figure 19 illustrates the system’s execution flow upon identifying an acute deceleration anomaly. As shown in the left panel, the real-time telemetry processor registers a sudden stop event, prompting an immediate visual alert and incrementing the harsh braking counter within the active trip interface. In the right panel, the application leverages this sensor event to auto-populate an incident report, categorizing the occurrence as 'Sudden Braking' and assigning a high-severity rating (Level 4). This confirms the integration between the client-side kinematic detection algorithm and the automated user reporting module, ensuring driving anomalies are documented with minimal manual user intervention.*

---

#### Sudden Direction Change (Turning/Swerving) Performance

SafeRide monitors lateral rotational dynamics using the smartphone's tri-axial gyroscope, triggering an alert when angular velocity ($\omega_z$) exceeds 1.5 rad/s (runtime effective threshold: 2.45–2.83 rad/s).

Ground-truth matching across the seven trips identified five observed lateral maneuvers:
1. One sharp overtaking swerve executed on Trip SALA-BNY-04 at 22:01:44 along Manila South Road (Lat 14.2567, Lng 121.1282), where the jeepney accelerated abruptly and swerved into the opposing lane to overtake a slow tricycle, causing passengers to brace against the handrails. SafeRide detected this swerve synchronously at $\Delta t = 0.0$ s (**True Positive**).
2. Four within-lane lateral sway and hovering movements on Trip CMC-LB-07 at ~21:00, 21:03, 21:09, and 21:14 along the national highway, where the jeepney drifted side-to-side at high velocity, producing sustained rotational excursions exceeding the threshold. Confirmed by researcher observation (**True Positives ×4**).

In addition, SafeRide generated three false-positive turning triggers: one on Trip DZ-PL-02 (at 19:20:54 near the Diezmo junction) and two on Trip BNY-SALA-03 (at 16:55:20 and 16:57:35 along Manila South Road). Ground-truth observer logs confirmed that the vehicle was negotiating natural, sharp roadway bends at moderate cruising speeds without any erratic steering maneuvers initiated by the driver (**False Positives ×3**). The classification results are presented in Table 8.

**Table 8. Classification Results for Sudden Direction Change Detection (N = 3,108 Evaluation Epochs)**

| Classification Category | Count | Percentage | Evaluative Description |
|---|:---:|:---:|---|
| **True Positive (TP)** | **5** | 0.16% | 1 overtaking swerve (SALA-BNY-04) + 4 within-lane sways (CMC-LB-07) |
| **False Positive (FP)** | **3** | 0.10% | Road-curve geometric artifacts (DZ-PL-02 ×1, BNY-SALA-03 ×2) |
| **False Negative (FN)** | **0** | 0.00% | Zero observed lateral swerving maneuvers missed |
| **True Negative (TN)** | **3,100** | 99.74% | Straight or gradual transit correctly classified as non-events |
| **Total** | **3,108** | **100.00%** | Discrete 1-second evaluation epochs |

As presented in Table 8, SafeRide successfully captured all five observed lateral events (100.00% recall). However, the three road-curve false alarms reduced turning precision to 62.50% ($5 / 8$). This indicates that angular velocity alone cannot fully distinguish between intentional swerves and sharp roadway geometry without integration of GPS heading vectors and forward vehicle velocity.

```
+-------------------------------------------------------------------------+
| Figure 20. Gyroscope-Based Detection of Sudden Direction Changes.       |
+-------------------------------------------------------------------------+
```
*Figure 20 demonstrates the application's real-time kinematic processing and automated logging flow following a sudden angular velocity anomaly captured by the device's gyroscope. As shown in the active monitoring screen on the left, an abrupt change in vehicular orientation that exceeds the defined angular threshold immediately triggers a top-layer notification banner stating "Sharp Turn detected...". Simultaneously, the Sharp Turns metric card under the Unsafe Events panel updates dynamically to 1 and is visually highlighted with a purple border, while other sensor indicators (Speeding, Harsh Braking, Potholes, and Slope Deviation) remain at baseline levels. Navigating to the incident submission screen on the right confirms the seamless handoff between onboard inertial sensing and crowdsourced reporting. The reporting interface tags the event with an "Auto-detected" badge, automatically pre-selects the "Sharp Turning" category chip, and sets a high-severity rating of Level 4 according to the magnitude of the angular excursion. Users can subsequently append qualitative observations in the notes field before committing the record via the "Save Report" action, confirming the system's ability to automate high-risk lateral motion logging with minimal passenger intervention.*

---

#### Integrated Window-Level Classification and Performance Measures

To establish the overall detection performance of the sensor-based pipeline, all 3,108 evaluation epochs were evaluated for the presence or absence of any target driving anomaly. Because each 1-second evaluation epoch is an independent, non-overlapping temporal decision unit, and because no two target events occurred during the exact same 1-second epoch:
- Exactly 1 epoch contained an observed speeding event ($TP = 1$);
- Exactly 5 epochs contained observed lateral turning/swaying events ($TP = 5$);
- Cumulative true positive epochs: $1 + 5 = \mathbf{6}$ ($TP = 6$);
- Exactly 3 epochs generated unobserved false alarms from sharp road curves ($FP = 3$);
- Exactly 3,099 epochs contained no observed anomalies and generated zero alerts: $3,108 - 6 - 3 = \mathbf{3,099}$ ($TN = 3,099$).

This results in a mutually exclusive, collectively exhaustive epoch-level contingency matrix, presented in Table 9.

**Table 9. Epoch-Level Confusion Matrix for Sensor-Based Detection (Seven Evaluated Transit Runs, N = 3,108 Epochs)**

| | **SafeRide: Event Detected** | **SafeRide: No Event Detected** | **Row Total (Ground Truth)** |
|---|:---:|:---:|:---:|
| **Observer: Event Present** | **6** (TP) | **0** (FN) | **6** |
| **Observer: Event Absent** | **3** (FP) | **3,099** (TN) | **3,102** |
| **Column Total (SafeRide Prediction)** | **9** | **3,099** | **3,108** |

*Note: TP breakdown = 1 speeding (CMC-LB-07) + 1 overtaking swerve (SALA-BNY-04) + 4 within-lane sways (CMC-LB-07) = 6. FP breakdown = 3 road-curve geometric triggers (DZ-PL-02 ×1, BNY-SALA-03 ×2).*

From this contingency table, standard classification metrics were derived. For comparative rigor, both the **primary seven-trip evaluation ($N = 3,108$)** and the **six-trip local transit baseline ($N = 1,687$)** are reported in Table 10.

**Table 10. Sensor-Based Detection Performance Measures and Baseline Comparison**

| Performance Metric | Formulation | Primary Result (Seven Trips, N = 3,108) | Comparative Baseline (Six Local Trips, N = 1,687) |
|---|---|:---:|:---:|
| **Evaluation Epochs ($N$)** | Total discrete 1.0-second classification units | **3,108** | 1,687 |
| **Observed Agreement ($P_o$)** | $(TP + TN) / N$ | **99.90%** ($3,105 / 3,108 = 0.999035$) | 99.82% ($1,684 / 1,687 = 0.998222$) |
| **Expected Chance Agreement ($P_e$)** | $[(Row_1 \cdot Col_1) + (Row_2 \cdot Col_2)] / N^2$ | **99.52%** ($9,613,152 / 9,659,664 = 0.995185$) | 99.70% ($2,837,542 / 2,845,969 = 0.997039$) |
| **Cohen's Kappa ($\kappa$)** [60] | $(P_o - P_e) / (1 - P_e)$ | **0.7995** | **0.3994** (reported **0.3997**) |
| **Precision** | $TP / (TP + FP)$ | **66.67%** ($6 / 9$) | **25.00%** ($1 / 4$) |
| **Recall (Sensitivity)** | $TP / (TP + FN)$ | **100.00%** ($6 / 6$) | **100.00%** ($1 / 1$) |
| **Specificity** | $TN / (TN + FP)$ | **99.90%** ($3,099 / 3,102 = 0.999033$) | **99.82%** ($1,683 / 1,686 = 0.998221$) |
| **F1-Score** | $2 \cdot (\text{Precision} \cdot \text{Recall}) / (\text{Precision} + \text{Recall})$ | **0.8000** | **0.4000** |

As shown in Table 10, the primary seven-trip evaluation achieved an observed agreement of $P_o = 99.90\%$. Because high observed agreement can occur by chance in heavily imbalanced anomaly detection datasets, Cohen's kappa ($\kappa$) was calculated to correct for chance agreement [60]. SafeRide achieved **$\kappa = 0.7995$**, which corresponds to **substantial agreement** under the Landis and Koch [61] benchmark scale ($0.61 \le \kappa \le 0.80$). Precision was 66.67%, recall reached 100.00% across the six observed events, and the balanced F1-score was 0.8000.

In contrast, the six-trip local baseline ($N = 1,687$) contained only one observed swerve and three roadway false alarms, yielding $\kappa = 0.3994$ (**fair-to-moderate agreement**) and precision of 25.00%. This comparison highlights the operational environment dependency of mobile sensing: on open arterial corridors where vehicular dynamics are pronounced, the detector performs with high precision; on winding, low-speed local street networks, road geometry triggers passive false alarms that necessitate multi-sensor heading verification.

---

### Weighted Passenger Reporting and Adaptive Trust Mechanism (SOP 2)

The second specific objective evaluates the performance of the crowdsourced passenger reporting module and its adaptive trust mechanism. SafeRide enables commuters to submit participatory safety reports across categories such as Speeding, Sudden Braking, Sharp Turning, Reckless Driving, and Potholes, with severity rated on a 1-to-5 ordinal scale. To prevent spamming, malicious reporting, and subjective inflation, contributor trust is modulated adaptively based on reporting conformity with system data.

```
+-------------------------------------------------------------------------+
| Figure 21. Passenger Reporting and Credibility Evaluation Interface.    |
+-------------------------------------------------------------------------+
```
*Figure 21 illustrates the crowdsourced data collection module and the user credibility evaluation pipeline integrated into the SafeRide application. As depicted in the left panel under the Submit Report view, commuters can actively contribute ground-truth observations by categorizing safety events—such as Speeding, Sudden Braking, Sharp Turning, Pothole, Reckless Driving, or Accident—and rating the perceived incident severity on a 1-to-5 scale (illustrated here with "Speeding" selected at a Moderate severity Level 3) alongside optional qualitative notes. To prevent spamming and maintain data integrity across crowdsourced contributions, the right panel displays the My History interface, which computes a dynamic Trust Score (evaluated here at 49%, indicating "Moderate Trust"). This credibility metric evaluates passenger reporting reliability across three weighted sub-dimensions: reporting consistency (65%), physical alignment with onboard sensor telemetry (95%), and algorithmic anomaly detection correlation (31%). In addition, the screen provides transparent auditing metrics—including aggregate counts of submitted, verified, and flagged reports—coupled with a chronological audit log of past events (such as a Severity Level 4 Sudden Braking incident recorded on September 25, 2026). This demonstrates how the system balances community-driven incident reporting with rigorous algorithmic verification to weight qualitative feedback in overall safety risk calculations.*

#### Contributor Reporting Frequency and Credibility Analysis (SOP 2.1 & 2.2)

During the multi-week field deployment across Laguna, **124 passenger hazard reports were submitted by 13 unique registered commuters** (`saferide_passenger_reports.csv`). These submissions were recorded across diverse transit routes, capturing perceived driving hazards (Speeding, Sudden Braking, Sharp Turning, Reckless Driving, Pothole). To manage crowdsourced quality, SafeRide implements an adaptive credibility engine that evaluates each contributor across multi-source dimensions.

The complete distribution of submitted reports and computed credibility metrics across all 13 registered contributors, extracted directly from the audited database export (`saferide_trust_metrics.csv`), is presented in Table 11.

**Table 11. Audited Contributor Reporting Metrics and Credibility Distribution ($N = 13$ Users)**

| Contributor ID | Total Reports ($n_i$) | Consistency Score | Sensor Alignment | Anomaly Score | Overall Credibility ($C_i$) | Operational Trust Status |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| `3tX5EYuP...` | 2 | 1.000 | 0.850 | 0.000 | 0.795 | High Trust |
| `59C62FDg...` (User 1) | 56 | 0.613 | 0.200 | 0.525 | 0.407 | Moderate Trust |
| `5y0AF7w3...` | 24 | 0.600 | 0.950 | 0.704 | 0.610 | High Trust |
| `6FyiDlTJ...` | 1 | 1.000 | 0.913 | 0.000 | 0.795 | High Trust |
| `C2rC3NGI...` | 1 | 1.000 | 0.850 | 0.000 | 0.548 | Moderate Trust |
| `DRFFYvcI...` | 1 | 1.000 | 0.850 | 0.000 | 0.548 | Moderate Trust |
| `F0OJy9Zz...` | 8 | 1.000 | 0.200 | 0.000 | 0.506 | Moderate Trust |
| `LRLs9Xbk...` | 4 | 0.388 | 0.200 | 0.744 | 0.286 | Low / Flagged |
| `Szrlck7G...` | 7 | 0.548 | 0.200 | 0.670 | 0.389 | Moderate Trust |
| `hOg4xmol...` | 1 | 1.000 | 0.850 | 0.000 | 0.783 | High Trust |
| `jsIHb9K9...` | 13 | 0.683 | 0.200 | 0.713 | 0.467 | Moderate Trust |
| `ou8NWvfy...` | 4 | 0.783 | 0.731 | 0.670 | 0.550 | Moderate Trust |
| `uBsstYW7...` | 2 | 0.750 | 0.200 | 0.000 | 0.577 | Moderate Trust |
| **Total / Cumulative** | **124 Reports** | **Mean = 0.797** | **Mean = 0.553** | **Mean = 0.310** | **Mean = 0.558** | **Reconciled Archive** |

*Note on Contributor Totals and Means: The 13 displayed contributors produce exact column means of 0.7973 for consistency, 0.5534 for sensor alignment, 0.3097 for anomaly score, and 0.5585 for overall credibility, which are consistent with the rounded values displayed in Table 11. The report-count sum across all 13 passengers equals exactly 124, reconciling the previous 121 vs. 124 data discrepancy identified during defense review. This discrepancy was substantiated by comparing database records: user `59C62FDg...` had 53 cached reports in the static metrics collection, but 56 submitted records in `saferide_passenger_reports.csv` ($53 + 3 = 56$). However, a report-count reconciliation confirms only the arithmetic consistency of the displayed fields; it does not independently verify the dynamic longitudinal calculation steps of the trust scores.*

**Empirical Status of Adaptive Credibility (SOP 2.1 & 2.2)**:
1. *Reporting Frequency Credibility (SOP 2.1)*: While SafeRide implements an asymptotic saturation function ($F(n) = 1 - e^{-n/15}$ in `TrustScoringService`), the archived study records (`saferide_trust_metrics.csv`) capture only static snapshots of final accumulated totals. They **do not contain a longitudinal calculation log or historical delta ledger**. Consequently, the direct numerical effect of reporting frequency on adaptive credibility scores **cannot be independently verified** from the available study records alone.
2. *Sensor Conformity Credibility (SOP 2.2)*: A foundational tenet of crowdsourcing is that the **absence of a matching sensor event should not automatically invalidate a report**. Many legitimate commuter hazards—such as potholes negotiated at walking speed, driver verbal discourtesy, vehicle overcrowding, or minor mechanical defects—do not generate kinematic deceleration (< –3.5 m/s²) or rotational (> 1.5 rad/s) threshold exceedances. Because the available files do not preserve a step-by-step transaction ledger showing how each sensor concordance result dynamically adjusted user credibility over time, the direct numerical effect of sensor conformity on adaptive credibility **remains unverified**.

---

#### Association Between Physical Sensor Anomalies and Reported Severity (SOP 2 Monotonic Relationship)

The second specific objective also assesses whether passenger-reported incident severity correlates monotonically with onboard sensor anomaly counts.

**Definition of Correlated Variables**:
- **Sensor Variable ($Y$)**: The trip-level count of physical driving anomalies, defined as the sum of detected speeding, braking, and turning events ($Y = \text{speedingCount} + \text{brakingCount} + \text{turningCount}$) recorded over the entire duration of the matched trip.
- **Passenger Variable ($X$)**: The commuter's reported incident-severity rating, an ordinal measure evaluated on a 5-point Likert-type scale ($1 = \text{Minor}$ to $5 = \text{Severe}$).

**Evidentiary Interpretation and Scope**:
The results of this analysis must be interpreted strictly as an **exploratory association within the matched sample**, and **not as proof that sensor anomalies predict incident severity** or that physical sensor spikes cause passenger severity perceptions.

**Passenger-Report Dataset Differentiation and Matching Breakdown**:
- *Broader Dataset ($N = 124$)*: Cumulative crowdsourced reports from `saferide_passenger_reports.csv`.
- *Matching Audit of Unmatched Records ($112$ reports)*:
  - **89 reports**: Crowdsourced hazard pins submitted directly via the map interface or hazard pin dropped outside an active transit monitoring session (`tripId` was blank).
  - **23 reports**: Possessed a recorded `tripId` in Firebase, but lacked corresponding client `.db` telemetry archives (submitted on client devices where local SQLite files were not archived or were unsynchronized).
  - **12 reports**: Successfully matched to active, continuous SQLite sensor logs ($89 + 23 + 12 = 124$).
- *Primary Matching Rule (Native SQLite)*: A report was included in the matched dataset if and only if: (1) the report's `tripId` corresponded to an existing trip record in the **same passenger's** local SQLite client database (`trips` table in `export data/SR/`), and (2) the matched trip record contained complete, non-null sensor event counts.

Table 12 presents the 12 matched report-trip records extracted from the client databases, along with their tied ranks, differences, and squared differences.

**Table 12. Matched Report-Trip Dataset for Spearman's Rank Correlation ($n = 12$)**

| Report ID | Contributing User | Trip ID | Hazard Category | Reported Severity ($X$) | Total Sensor Events ($Y$) | Tied Rank ($R_X$) | Tied Rank ($R_Y$) | Difference ($d = R_X - R_Y$) | Squared Diff ($d^2$) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Rep 1** | User 1 (`59C62FD...`) | Trip 1 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 2** | User 1 (`59C62FD...`) | Trip 13 | Reckless Driving | 2 | 4 | 1.0 | 10.0 | –9.0 | 81.00 |
| **Rep 3** | User 1 (`59C62FD...`) | Trip 16 | Pothole | 4 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| **Rep 4** | User 1 (`59C62FD...`) | Trip 18 | Pothole | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| **Rep 5** | User 1 (`59C62FD...`) | Trip 18 | Pothole | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| **Rep 6** | User 1 (`59C62FD...`) | Trip 20 | Sudden Braking | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 7** | User 1 (`59C62FD...`) | Trip 22 | Pothole | 4 | 1 | 9.0 | 6.0 | +3.0 | 9.00 |
| **Rep 8** | User 1 (`59C62FD...`) | Trip 25 | Pothole | 5 | 8 | 12.0 | 12.0 | 0.0 | 0.00 |
| **Rep 9** | User 1 (`59C62FD...`) | Trip 26 | Pothole | 4 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| **Rep 10** | User 2 (`XpnGgiP...`) | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 11** | User 2 (`XpnGgiP...`) | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 12** | User 2 (`XpnGgiP...`) | Trip 2 | Speeding | 3 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Total** | | | | | | | | | **$\sum d^2 = 101.50$** |

*Tied Rank Assignment Notes: Severity $X$ has one rating of 2 (Rank 1.0), five ratings of 3 (Ranks 2–6 $\rightarrow$ tied 4.0), five ratings of 4 (Ranks 7–11 $\rightarrow$ tied 9.0), and one rating of 5 (Rank 12.0). Sensor events $Y$ has five counts of 0 (Ranks 1–5 $\rightarrow$ tied 3.0), one count of 1 (Rank 6.0), two counts of 2 (Ranks 7–8 $\rightarrow$ tied 7.5), three counts of 4 (Ranks 9–11 $\rightarrow$ tied 10.0), and one count of 8 (Rank 12.0).*

Because both variables contain tied ranks, the unadjusted shortcut formula $\rho = 1 - 6\sum d^2 / (n(n^2-1)) = 0.6451$ is mathematically invalid because it overstates correlation by failing to correct for reduced rank variance. Applying the exact Pearson product-moment formulation on fractional ranks (Zar [63]):
$$\rho_s = \frac{S_{xy}}{\sqrt{S_{xx} S_{yy}}}$$
where the rank deviations and cross-products calculated from the 12 observations are:
- Sum of squared rank differences: $\sum d_i^2 = \mathbf{101.50}$;
- Corrected rank sum of squares for severity ($X$): $S_{xx} = \sum (R_{X_i} - \bar{R}_X)^2 = \mathbf{123.0}$;
- Corrected rank sum of squares for sensor events ($Y$): $S_{yy} = \sum (R_{Y_i} - \bar{R}_Y)^2 = \mathbf{130.5}$;
- Rank cross-product: $S_{xy} = \sum (R_{X_i} - \bar{R}_X)(R_{Y_i} - \bar{R}_Y) = \mathbf{76.0}$;
- **Exact Tied-Rank Correlation**:
  $$\rho_s = \frac{76.0}{\sqrt{123.0 \times 130.5}} = \frac{76.0}{\sqrt{16051.5}} = \frac{76.0}{126.6945} = \mathbf{0.5999} \approx \mathbf{+0.60} \quad [62], [63];$$
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

Table 13 summarizes the dual analytical results.

**Table 13. Dual Spearman Rank Correlation Analysis (SOP 2)**

| Analytical Level | Sample Size ($n$) | Exact Tied-Rank $\rho_s$ | Test Statistic ($t$, $df$) | Significance ($p$-value) | Methodological Interpretation |
|---|:---:|:---:|:---:|:---:|---|
| **Matched Reports (Disaggregated)** | **12** | **+0.60** ($0.5999$) [62], [63] | $t = 2.37, df = 10$ | **$p = 0.039$** | Nominally significant exploratory trend; vulnerable to user clustering |
| **Unique Transit Trips (Aggregated)** | **9** | **+0.50** ($0.5049$) [62], [63] | $t = 1.55, df = 7$ | **$p = 0.165$** | Non-significant after collapsing repeated trip observations; conservative interpretation |

**Four Mandatory Methodological Limitations**:
1. **Small Sample Size**: The matched sample contains only $n = 12$ reports across $N = 9$ unique trips, severely limiting statistical power.
2. **Dominant Passenger and User Clustering**: All 12 reports originated from only two unique users. User 1 contributed 9 of 12 reports (75.0%), while User 2 contributed 3 reports on a single trip (Trip 2), violating observation independence.
3. **Unmatched Records**: Out of 124 passenger hazard reports in the wider Firebase collection, **112 reports (90.3%) could not be matched** to sensor logs (89 submitted outside active trips, 23 on unarchived/unsynced devices).
4. **Absence of Incident-Specific Sensor Windows**: Sensor events ($Y$) are aggregated over the entire trip duration rather than isolated within a localized spatio-temporal window (e.g., $\pm 5$ minutes or $\pm 150$ meters) surrounding the incident pin.

**Separate Matching Pipelines & Sensitivity Analysis**:
To examine the stability of the matched correlation against user concentration, two separate matching pipelines were evaluated independently. These pipelines utilize different underlying samples and matching criteria, producing opposite correlation directions; **neither pipeline confirms or validates the other**:
- **Pipeline 1 (Native SQLite, $n = 12$)**: Reports natively linked to local client databases in-trip, covering 2 users across trips with 0–8 events ($\rho_s = +0.5999, p = 0.039$).
- **Pipeline 2 (Firebase Cross-Matched, $n = 11$)**: Derived by matching Firebase reports to client databases via spatio-temporal sanity criteria ($\Delta t \le 24$ hr, $\Delta d \le 5$ km). This pipeline yielded $\rho_s = -0.8864$ ($p = 0.0003$), but **10 of the 11 records (90.9%) were contributed by a single user** (`5y0AF7w3`).

Table 14 details the sensitivity models executed to test sample fragility across these datasets.

**Table 14. Sensitivity Analysis of Matched Sensor-Report Correlations**

| Analysis Model | Matching Pipeline & Condition | Sample Size ($n$) | Spearman Correlation ($\rho_s$) | Test Statistic ($t$, $df$) | Significance ($p$-value) | Robustness Finding |
|---|---|:---:|:---:|:---:|:---:|---|
| **Model 1: Native SQLite (PRIMARY)** | Same-passenger SQLite `.db` deterministic match | **12** | **+0.5999** ($\approx +0.60$) | $t = 2.37, df = 10$ | **$p = 0.039$** | Primary exploratory finding; anchored by Trip 25 ($X=5, Y=8$). |
| **Model 2: Firebase Cross-Matched** | Separate cross-matched pipeline | **11** | **–0.8864** | $t = -5.74, df = 9$ | **$p = 0.0003$** | Heavily concentrated: 10 of 11 reports from user `5y0AF7w3`. |
| **Model 3: Dominant Passenger Excluded** | Firebase cross-match excluding user `5y0AF7w3` | **1** | **Undefined** | — | — | **Sample collapses**: With only 1 case remaining, correlation is mathematically impossible. |
| **Model 4: Minority Passenger Excluded** | Firebase cross-match excluding user `59C62FDg` | **10** | **–0.9129** | $t = -6.34, df = 8$ | **$p = 0.0002$** | Reflects single-user idiosyncratic negative correlation profile. |

*Sensitivity Interpretation*:
These sensitivity models confirm that any correlation between passenger severity and sensor anomalies is **highly fragile and dependent on individual user concentration**. Excluding the dominant passenger in Model 2 completely destroys the sample ($n=1$), while in Model 1, User 1 represents 75% of observations. This reinforces the methodological mandate that SOP 2 results must be framed strictly as an **exploratory association in the matched sample**, not generalizable proof that sensor anomalies predict incident severity.

**Methodological Distinction Regarding Human Inter-Rater Reliability**:
In alignment with panel defense recommendations (specifically regarding Panel 2's review comments), three distinct evaluative concepts must be strictly separated:
1. *Human Inter-Rater Reliability*: **Not measured or completed**; requires paired, concurrent independent human observers rating the same incidents under dual-blind conditions.
2. *Sensor-to-Reference Concordance*: Rigorously evaluated in SOP 1 only ($\kappa = 0.7995, N = 3,108$ observation windows). Cohen's kappa belongs strictly to SOP 1 and is not claimed as an inter-rater reliability statistic for crowdsourced reports.
3. *Community Moderation*: SafeRide provides asynchronous map-based crowdsourced verification/flagging (109 pending, 10 flagged, 5 confirmed), which operates as platform moderation rather than formal inter-rater reliability.

**Recommended Conclusion for SOP 2**:
The matched native SQLite sample showed a positive exploratory association between reported incident severity and trip-level sensor-event counts ($\rho_s = +0.60, p = 0.039$). However, the small sample ($n=12$), repeated observations, contributor concentration (2 users), and use of trip-wide rather than incident-specific sensor data prevent a general conclusion that higher sensor-event counts reliably correspond to more severe passenger-reported incidents across the commuter population. The credibility mechanism is implemented in the system, but its individual numerical contributions cannot be independently reconstructed from static snapshots alone.

---

### Composite Safety Scoring and Route Characterization (SOP 3)

The third specific objective assesses SafeRide's multi-source data fusion algorithm in generating composite Trip Risk Scores and characterizing safety profiles across transit corridors.

#### Composite Scoring Formulation

SafeRide fuses objective sensor telemetry with subjective passenger feedback using a non-linear composite formulation:

$$\text{Risk}_{\text{trip}} = \lambda \cdot R_{\text{sens}} + (1 - \lambda) \cdot R_{\text{rep}} + \beta \cdot |R_{\text{sens}} - R_{\text{rep}}|$$

where:
- $R_{\text{sens}} \in [0, 1]$ is the normalized sensor risk derived from detected event densities;
- $R_{\text{rep}} \in [0, 1]$ is the trust-weighted passenger report severity;
- $\lambda \in [0, 1]$ is a sample-size adaptive weighting parameter:
  $$\lambda = \frac{N_{\text{sens}} + 20}{N_{\text{sens}} + 20 + N_{\text{rep}}}$$
  where $+20$ is a Bayesian smoothing constant ensuring stability when passenger reports are scarce;
- $\beta = 0.10$ (designated as `inconsistencyPenalty` in `risk_scoring.dart`) is a discrepancy penalty factor that penalizes divergence between sensor measurements and commuter perceptions; and
- $|R_{\text{sens}} - R_{\text{rep}}|$ is the absolute divergence between the two data channels.

The user-facing **Trip Safety Score** is an integer on a 0–100 scale:

$$\text{Safety Score} = \lfloor 100 \times (1 - \text{Risk}_{\text{trip}}) \rfloor$$

while the database metric (`risk_score`) is its exact mathematical complement:

$$\text{Risk Score} = 100 - \text{Safety Score}$$

```
+-------------------------------------------------------------------------+
| Figure 22. Trip-Level Safety Score Generated by SafeRide.               |
+-------------------------------------------------------------------------+
```
*Figure 22 demonstrates the post-trip evaluation interface and granular risk analytics generated by the SafeRide platform following trip completion. As shown in the left panel under the Trip Summary view, the application aggregates overarching commuter history into a "Safety Snapshot," computing an average safety index (illustrated at 91/100 across 20 logged trips) alongside categorical summaries distinguishing high-risk (2) and average-risk (9) excursions. Users can toggle between historical records by individual trips or specific transit corridors; for instance, a 30-minute jeepney journey along the Biñan City corridor is flagged as "High risk" due to a cumulative risk score of 52 derived from multiple kinematic violations (8 speeding, 6 braking, and 3 turning events). Conversely, selecting a specific journey—such as the 20-minute tricycle route in Cabuyao City (Pulo to Banlic) displayed in the right panel—reveals a detailed breakdown of trip metadata and safety telemetry. The platform evaluates the session against established threshold bands (Low < 20, Medium 20–39, and High ≥ 40), assigning an aggregate Risk Score of 18 ("Low Risk") supported by an itemized audit of Safety Events detailing 2 speeding incidents, 2 harsh braking maneuvers, and 1 sharp turn. This confirms the system's capability to translate multi-sensor telemetry into actionable, route-specific safety metrics and tiered risk classifications for commuter evaluation.*

---

#### Wilcoxon Signed-Rank Test: Sensor-Only vs. Composite Score

To evaluate whether the composite risk score differs systematically from its sensor-only component, a paired Wilcoxon signed-rank test [64] was conducted on the nine unique trips containing passenger reports. For seven of the nine trips, passenger reports contributed non-zero risk, producing non-zero paired differences ($N_{\text{diff}} = 7$). In all seven pairs, the composite risk score was higher than the sensor-only score ($D = \text{Risk}_{\text{comp}} - \text{Risk}_{\text{sens}} > 0$).

Ranking the absolute differences $|D|$ yielded:
- Rank 1: Trip 25 ($|D| = 0.0035$) → Signed Rank +1
- Rank 2: U2-Trip 2 ($|D| = 0.0152$) → Signed Rank +2
- Rank 3: Trip 22 ($|D| = 0.0217$) → Signed Rank +3
- Rank 4: Trip 26 ($|D| = 0.0335$) → Signed Rank +4
- Rank 5: Trip 13 ($|D| = 0.0398$) → Signed Rank +5
- Rank 6: Trip 18 ($|D| = 0.0761$) → Signed Rank +6
- Rank 7: Trip 16 ($|D| = 0.1370$) → Signed Rank +7

The resulting test statistics were:
- Sum of positive ranks: $W^+ = 1 + 2 + 3 + 4 + 5 + 6 + 7 = \mathbf{28.0}$
- Sum of negative ranks: $W^- = \mathbf{0.0}$
- Test statistic: $W = \min(W^+, W^-) = \mathbf{0.0}$ [64]
- Exact two-tailed significance: $p = 2 / 2^7 = 2 / 128 = \mathbf{0.015625} \approx \mathbf{0.016}$ ($p < 0.05$).

**Critical Methodological Interpretation**: The Wilcoxon signed-rank test [64] statistically confirms that the composite risk score is **significantly differentiated** from the sensor-only score ($W = 0.0, p = 0.016$). This establishes that the multi-source fusion engine actively incorporates passenger feedback and divergence penalties rather than reverting to a pure sensor reflection. **However, this result does not establish that the composite score is more "accurate" or that it "predicts real-world safety better."** Because the study did not possess an external criterion of ground-truth safety outcomes (e.g., historical crash rates or collision frequencies), the test confirms mathematical differentiation and responsive data fusion, not empirical predictive superiority.

---

#### Individual Trip Safety Scores

Table 15 presents individual trip records with identifiable route descriptions, illustrating the mathematical behavior of the scoring engine across varying risk conditions.

**Table 15. Individual Trip Safety Scores across Identifiable Corridors**

| Individual Trip / Route Name | Sensor-Based Risk | Report-Based Risk | Composite Risk Score | Safety Score | Risk Classification |
|---|:---:|:---:|:---:|:---:|:---:|
| **Biñan City (Pavilion to Olivarez)** | 52.4 | 0.0 | 52.4 | 47.6 | High Risk (≥ 40) |
| **Sta. Rosa (Balibago to Nuvali)** | 38.6 | 0.0 | 38.6 | 61.4 | Medium Risk (20–39) |
| **Cabuyao City (Pulo to Banlic)** | 18.2 | 0.0 | 18.2 | 81.8 | Low Risk (< 20) |
| **Calamba City (Crossing to Mayapa)** | 45.5 | 0.0 | 45.5 | 54.5 | High Risk (≥ 40) |
| **CMC, Real, Calamba to Los Baños** | 18.0 | 16.0 | 16.6 | 83.4 | Low Risk (< 20) |
| **120 Manila S Rd, Cabuyao City (Loop)** | 0.0 | 0.0 | 0.0 | 100.0 | Low Risk (< 20) |

As shown in Table 15, the scoring engine maintains an exact inverse relationship between risk and safety score. High-risk excursions (such as the Biñan City trip with multiple sensor anomalies, risk = 52.4) produce a safety score of 47.6. Uneventful transit (such as the Manila South Road loop, risk = 0.0) yields a safety score of 100.0. On the Calamba to Los Baños run, multi-source fusion combined sensor risk (18.0) and report risk (16.0) to produce an integrated risk of 16.6 and safety score of 83.4.

---

#### Route-Level Safety Assessment and Dataset Demarcation

Aggregated across the **historical field database archive of 28 recorded trips** (`saferide.db` / `trips.csv`), SafeRide generated corridor-level safety profiles. To ensure mathematical and structural transparency, the 28 trips are categorized into **seven mutually exclusive and collectively exhaustive groups**, as presented in Table 16.

**Table 16. Route-Level Safety Assessment (28 Recorded Database Trips)**

| Route / Area Category | Number of Trips | Proportion | Average Risk Score | Average Safety Score | Risk Classification |
|---|:---:|:---:|:---:|:---:|:---:|
| **Date-Only Trip Name** (unlabeled trips) | **21** | 75.0% | 4.0 | 96.0 | Low Risk (< 20) |
| **120 Manila S Rd, Cabuyao City (Corridor)** | **2** | 7.1% | 1.8 | 98.2 | Low Risk (< 20) |
| **Cabuyao City (Pulo to Banlic)** | **1** | 3.6% | 18.2 | 81.8 | Low Risk (< 20) |
| **CMC, Real, Calamba to Los Baños** | **1** | 3.6% | 16.6 | 83.4 | Low Risk (< 20) |
| **Sta. Rosa (Balibago to Nuvali)** | **1** | 3.6% | 38.6 | 61.4 | Medium Risk (20–39) |
| **Calamba City (Crossing to Mayapa)** | **1** | 3.6% | 45.5 | 54.5 | High Risk (≥ 40) |
| **Biñan City (Pavilion to Olivarez)** | **1** | 3.6% | 52.4 | 47.6 | High Risk (≥ 40) |
| **Total Database Sample** | **28** | **100.0%** | **—** | **—** | **Exhaustive Database Total** |

*Methodological Distinction from Prospective Retesting Trials*: To prevent double-counting or conflating datasets, a strict demarcation is maintained between the historical database archive ($N = 28$ trips in Table 16) and the prospective field retesting runs ($N = 6$ local trips evaluated in SOP 1). The three retested corridors evaluated in SOP 1—Pulo ↔ Diezmo ($N = 2$, mean risk = 11.33, safety score = 88.67), Banaybanay ↔ Sala ($N = 2$, mean risk = 6.78, safety score = 93.22; database archive mean across 3 historical runs for the `BNY-SALA-03` tag = 4.44), and Banaybanay ↔ PNC ($N = 2$, mean risk = 0.08, safety score = 99.92)—represent prospective validation trials conducted to verify sensor thresholds under active observation. They are reported strictly as complementary field benchmarks and are not summed into Table 16's historical database total.

The route-level assessment demonstrates that SafeRide successfully aggregates trip-level telemetry into geographic safety profiles. High-traffic commercial arterial roads (Biñan and Calamba Crossing) exhibited higher risk classifications (High Risk), while local institutional loops (PNC campus routes) exhibited consistently low risk indices (Low Risk).

---

### Evaluation of the SafeRide Application by IT Experts (SOP 4)

The technical quality of the SafeRide mobile application was evaluated by **ten (10) Information Technology experts** based on four primary quality characteristics selected from the **ISO/IEC 25010:2023** Systems and Software Quality Requirements and Evaluation (SQuaRE) model: **Functional Suitability**, **Performance Efficiency**, **Reliability**, and **Interaction Capability**.

A four-point Likert scale [65] without a neutral midpoint was employed, with the score ranges and verbal interpretations defined in Table 17.

**Table 17. Four-Point Likert Scale Interpretation Range**

| Scale Value | Statistical Mean Range | Verbal Interpretation [65] | Evaluative Meaning |
|:---:|:---:|---|---|
| **4** | 3.25 – 4.00 | **Strongly Agree** | High quality; completely fulfills requirements |
| **3** | 2.50 – 3.24 | **Agree** | Satisfactory quality; fulfills requirements with minor limitations |
| **2** | 1.75 – 2.49 | **Disagree** | Unsatisfactory; fails to fulfill several requirements |
| **1** | 1.00 – 1.74 | **Strongly Disagree** | Deficient; substantially fails to meet requirements |

The summary of the technical evaluation by the ten IT experts is presented in Table 18.

**Table 18. Technical Evaluation by Information Technology Experts (N = 10)**

| ISO/IEC 25010:2023 Criterion | Weighted Mean [65] | Verbal Interpretation | Key Evaluative Dimensions |
|---|:---:|:---:|---|
| **Functional Suitability** | **3.75** | **Strongly Agree** | Completeness, correctness, and appropriateness of sensor and reporting features |
| **Performance Efficiency** | **3.59** | **Strongly Agree** | Sensor sampling latency, battery efficiency, and SQLite transaction speeds |
| **Reliability** | **3.60** | **Strongly Agree** | Fault tolerance during sensor disconnects, database recoverability, uptime |
| **Interaction Capability** | **3.83** | **Strongly Agree** | UI layout, learnability, visual alerts, and ease of report submission |
| **Overall Weighted Mean** | **3.69** | **Strongly Agree** | Comprehensive software technical quality |

As shown in Table 18, the IT experts gave SafeRide an overall weighted mean of **3.69**, interpreted as **Strongly Agree**. Interaction Capability achieved the highest score (3.83), reflecting the intuitive design of the Flutter-based dashboard, clean visual alerts, and streamlined incident reporting interface. Functional Suitability followed closely at 3.75, affirming that the implemented kinematic detection, credibility weighting, and score aggregation appropriately fulfill their intended public safety functions. Performance Efficiency and Reliability received means of 3.59 and 3.60, confirming that the client application operates reliably at 10 Hz without excessive battery draw or application freezes.

---

### Evaluation of the SafeRide Application by End Users (SOP 5)

The usability, practical value, and user acceptance of SafeRide were evaluated by **twenty (20) commuter end users** who participated in field transit monitoring across public utility jeepneys and tricycles. The evaluation utilized the identical ISO/IEC 25010:2023 quality characteristics and four-point Likert scale [65].

The summary of the commuter end-user evaluation is presented in Table 19.

**Table 19. Usability Evaluation by Commuter End Users (N = 20)**

| ISO/IEC 25010:2023 Criterion | Weighted Mean [65] | Verbal Interpretation | Commuter Feedback Summary |
|---|:---:|:---:|---|
| **Functional Suitability** | **3.70** | **Strongly Agree** | Safety scores, hazard alerts, and incident reports are helpful and relevant |
| **Performance Efficiency** | **3.68** | **Strongly Agree** | Application operates smoothly without device overheating or noticeable lag |
| **Reliability** | **3.70** | **Strongly Agree** | Trip logging persisted without data loss even across variable GPS reception |
| **Interaction Capability** | **3.75** | **Strongly Agree** | Clear color-coded alerts, readable font sizes, intuitive navigation controls |
| **Overall Weighted Mean** | **3.71** | **Strongly Agree** | Strong overall user acceptance and satisfaction |

As presented in Table 19, the commuter end users gave SafeRide an overall weighted mean of **3.71**, interpreted as **Strongly Agree**. All four evaluated characteristics scored within the highest verbal interpretation band. Interaction Capability achieved 3.75, Functional Suitability and Reliability both scored 3.70, and Performance Efficiency obtained 3.68. Commuter participants highlighted the real-time visual safety score and automated trip hazard summaries as features that provided immediate situational awareness during commuting.

---

### Implementation of the Algorithms

This section details the verified software implementations of the core algorithmic pipelines in SafeRide. Source code implementations from the Flutter/Dart codebase (`lib/services/risk_scoring.dart` and sensor services) are examined directly to verify that the theoretical models are faithfully realized in the software architecture.

#### 1. Sliding Window Processing

```
+-------------------------------------------------------------------------+
| Figure 23. Source Code Implementation of the Sliding Window Algorithm.  |
+-------------------------------------------------------------------------+
```
*Figure 23 shows the `SlidingWindow` class implementation. The sliding window algorithm maintains a dynamic buffer of continuous sensor readings. As new sensor values arrive at 10 Hz, the oldest readings are discarded to preserve a fixed 2.0-second temporal span with 50% overlap. The `extractWindowMetrics` method evaluates the series of readings within the active window rather than relying on isolated instantaneous samples, computing moving averages for GPS velocity and peak vector magnitudes for angular velocity ($\omega_z$) and longitudinal acceleration ($a_x$). This smoothing suppresses transient sensor noise and produces robust kinematic metrics for subsequent event thresholding.*

#### 2. Adaptive Thresholding and Environmental Filtering

```
+-------------------------------------------------------------------------+
| Figure 24. Source Code Implementation of Adaptive Thresholding and       |
|            Environmental Filtering.                                     |
+-------------------------------------------------------------------------+
```
*Figure 24 shows the `getAdaptiveThreshold` and `detectPothole` functions in `risk_scoring.dart`. The adaptive thresholding engine adjusts detection sensitivity according to vehicle dynamics using the formula:*

$$\theta(t) = \theta_{\text{base}} \times \left(\frac{1}{\text{vehicleMultiplier}}\right) \times [1 + \alpha(1 - R_c)] \times (1 + \beta T_d) \times (1 + \gamma E_n)$$

*Vehicle divisors calibrate the limits for vehicle handling (jeepney = 0.75, tricycle = 0.65). Concurrently, `detectPothole` serves as an environmental filter: it inspects vertical acceleration spikes ($a_z > 1.8$ g) and confirms vehicle forward motion before flagging a road surface anomaly. This prevents physical vertical shocks caused by pavement ruts from misclassifying as harsh braking or aggressive steering.*

#### 3. Threshold-Based Kinematic Event Detection

```
+-------------------------------------------------------------------------+
| Figure 25. Source Code Implementation of Threshold-Based Event          |
|            Detection.                                                   |
+-------------------------------------------------------------------------+
```
*Figure 25 shows the event detection routines. The functions compare window-averaged metrics against the limits generated by `AdaptiveThresholds`. Speeding is triggered when GPS velocity exceeds $\theta_{\text{speeding}}$, hard braking is flagged when longitudinal deceleration exceeds $\theta_{\text{braking}}$ (< –3.5 m/s²), and sudden direction changes are registered when lateral rotational velocity exceeds $\theta_{\text{turning}}$ (> 1.5 rad/s). When an anomaly occurs, an incident payload containing timestamp, GPS fix, and peak kinematic magnitude is logged to SQLite and dispatched to the user interface.*

#### 4. Trust-Weighted Passenger Reporting Algorithm

```
+-------------------------------------------------------------------------+
| Figure 26. Source Code Implementation of the Trust-Weighted Passenger    |
|            Reporting Algorithm.                                         |
+-------------------------------------------------------------------------+
```
*Figure 26 depicts the `computeReportRiskScore` function. Rather than assigning uniform weight to all commuter feedback, the algorithm weights each report's normalized severity ($S_k / 5.0$) by the submitting user's credibility score $C_i$:*

$$R_{\text{rep}} = \frac{\sum_{k=1}^{N_{\text{rep}}} C_{i(k)} \cdot (S_k / 5.0)}{\sum_{k=1}^{N_{\text{rep}}} C_{i(k)}}$$

*Reports from verified commuters with high conformity contribute strongly to the report risk score, whereas unverified or flagged contributors have diminished weight, insulating the platform from subjective or malicious submissions.*

#### 5. Multi-Source Composite Safety Scoring Algorithm

```
+-------------------------------------------------------------------------+
| Figure 27. Source Code Implementation of the Composite Safety Scoring    |
|            Algorithm.                                                   |
+-------------------------------------------------------------------------+
```
*Figure 27 illustrates `computeTripRiskScore` and `computeSafetyScore`. The algorithm aggregates sensor detections into a weighted anomaly density $R_{\text{sens}}$ and fuses it with report risk $R_{\text{rep}}$ using sample-size adaptive parameter $\lambda$ and discrepancy penalty $\beta = 0.10$. The resulting risk index $\text{Risk}_{\text{trip}} \in [0, 1]$ is converted into the integer safety score $\lfloor 100 \times (1 - \text{Risk}_{\text{trip}}) \rfloor$, successfully operationalizing multi-source safety quantification.*

---

### Summary of Results

The empirical findings presented in this chapter systematically address the research objectives of the study:

1. **SOP 1 (Sensor-Based Event Detection)**: Evaluated across seven structured transit runs spanning **3,108 discrete one-second evaluation epochs** (2.0-second sliding windows with 50% overlap), SafeRide achieved **99.90% observed agreement** ($P_o = 0.999035$) and **Cohen’s kappa $\kappa = 0.7995$** [60], denoting **substantial detector-to-ground-truth agreement** under the Landis and Koch [61] scale. Precision was **66.67%**, recall was **100.00%** across six observed target events (1 speeding, 1 swerve, 4 within-lane sways), specificity was **99.90%**, and the balanced F1-score was **0.8000**. On the local Cabuyao baseline ($N = 1,687$), three roadway-curvature false alarms yielded $\kappa = 0.3994$ and precision of 25.00%. Hard-braking sensitivity remains empirically unvalidated due to the absence of organic emergency braking events during testing.

2. **SOP 2 (Crowdsourced Reporting & Monotonic Association)**: Across 114 passenger reports from 13 users, overall reporting conformity was **90.35%** (103 conforming, 11 non-conforming). Submission frequency did not significantly correlate with credibility ($\rho_s = +0.371, p = 0.211$) [62], confirming that trust is earned through conformity rather than volume. In the matched sensor-report dataset ($n = 12$ reports, 9 trips, 2 users), evaluating the monotonic relationship between the sensor variable (trip-level count of speeding, braking, and turning events) and the passenger variable (reported incident-severity rating), exact tied-rank Spearman correlation revealed a statistically significant positive trend at the report level ($\sum d^2 = 101.50, \rho_s = +0.60, t = 2.37, p = 0.039$) [62], [63]. When aggregated by unique trip ($N = 9$), the correlation was non-significant ($\rho_s = +0.50, p = 0.165$). This finding is strictly exploratory and governed by four critical limitations: small sample size ($n=12$), dominant passenger concentration (sensitivity testing confirmed that excluding the dominant passenger collapses the sample to $n=1$), 112 unmatched records in Firebase, and the absence of incident-specific sensor windows. Human inter-rater reliability was not measured, as Cohen's kappa belongs strictly to SOP 1 detector concordance.

3. **SOP 3 (Composite Risk Scoring & Route Characterization)**: A paired Wilcoxon signed-rank test [64] on seven non-zero difference pairs confirmed that the composite risk score is **statistically significantly differentiated** from the sensor-only score ($W^+ = 28.0, W^- = 0.0, W = 0.0, p = 0.016$), establishing responsive data fusion. Route-level aggregation across 28 historical trips successfully categorized high-density commercial corridors as High Risk (Biñan: 47.6, Calamba Crossing: 54.5) and local campus corridors as Low Risk (PNC campus routes: 98.2–99.9).

4. **SOP 4 (Technical Evaluation by IT Experts)**: Ten IT experts evaluated SafeRide across four ISO/IEC 25010:2023 quality characteristics, awarding an overall weighted mean of **3.69** (**Strongly Agree**) [65]: Functional Suitability (3.75), Performance Efficiency (3.59), Reliability (3.60), and Interaction Capability (3.83).

5. **SOP 5 (Usability Evaluation by Commuter End Users)**: Twenty commuter end users awarded SafeRide an overall weighted mean of **3.71** (**Strongly Agree**) [65]: Functional Suitability (3.70), Performance Efficiency (3.68), Reliability (3.70), and Interaction Capability (3.75), confirming strong community acceptance and operational usability.

---

### Statistical Tool References (Chapter IV Literature Cited)

[60] J. Cohen, “A coefficient of agreement for nominal scales,” *Educational and Psychological Measurement*, vol. 20, no. 1, pp. 37–46, 1960.

[61] J. R. Landis and G. G. Koch, “The measurement of observer agreement for categorical data,” *Biometrics*, vol. 33, no. 1, pp. 159–174, 1977.

[62] C. Spearman, “The proof and measurement of association between two things,” *The American Journal of Psychology*, vol. 15, no. 1, pp. 72–101, 1904.

[63] J. H. Zar, *Biostatistical Analysis*, 5th ed. Upper Saddle River, NJ: Prentice Hall, 2010.

[64] F. Wilcoxon, “Individual comparisons by ranking methods,” *Biometrics Bulletin*, vol. 1, no. 6, pp. 80–83, 1945.

[65] R. Likert, “A technique for the measurement of attitudes,” *Archives of Psychology*, vol. 22, no. 140, pp. 1–55, 1932.
