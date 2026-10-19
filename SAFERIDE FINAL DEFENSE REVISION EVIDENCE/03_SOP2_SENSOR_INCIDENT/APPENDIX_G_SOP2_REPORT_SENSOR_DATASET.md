# APPENDIX G: SOP 2 MATCHED REPORTS, SENSOR COUNTS, AND RANK CALCULATIONS

This appendix provides the complete dataset, rank assignments, and comparative statistical calculations evaluating the monotonic relationship between crowd-reported hazard severity and sensor-detected driving anomalies (SOP 2).

---

### Part 1. Distinction Between Passenger-Report Datasets

A critical methodological distinction exists between the two passenger-report datasets accumulated by SafeRide:
1. **Broader Conformity and Trust Dataset ($N = 124$ reports)**:
   - Stored in `saferide_passenger_reports.csv` across all system testing phases in Laguna.
   - Contributed by commuter participants across diverse transit lines, used to evaluate general reporting frequency, trust-weight distribution, and high-level hazard category distributions.
   - Includes standalone passenger submissions where continuous sensor logging was inactive or where trip records were unlinked.
2. **Matched Sensor-Report Dataset ($n = 12$ reports)**:
   - Comprises reports submitted during trips where active, concurrent smartphone sensor logging was fully captured and stored in SQLite client databases.
   - Enables direct pairing between the qualitative severity reported by the rider and the quantitative physical anomaly count detected by the vehicle sensors.
   - Represents the dataset analyzed for Spearman’s rank correlation (SOP 2).

---

### Part 2. Paired Dataset for Spearman's Rank Correlation

Table G-1 details the 12 matched report-trip records extracted from the client databases (`saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db` and `saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db`).

**Table G-1. Matched Report-Trip Dataset with Tied Ranks and Differences**

| Report ID | Contributing User | Trip ID | Hazard Category | Reported Severity ($X$) | Speeding Count | Braking Count | Turning Count | Total Sensor Events ($Y$) | Tied Rank ($R_X$) | Tied Rank ($R_Y$) | Difference ($d = R_X - R_Y$) | Squared Diff ($d^2$) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Rep 1** | User 1 | Trip 1 | Speeding | 3 | 0 | 0 | 0 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 2** | User 1 | Trip 13 | Reckless Driving | 2 | 0 | 0 | 4 | 4 | 1.0 | 10.0 | –9.0 | 81.00 |
| **Rep 3** | User 1 | Trip 16 | Pothole | 4 | 0 | 0 | 2 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| **Rep 4** | User 1 | Trip 18 | Pothole | 4 | 0 | 0 | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| **Rep 5** | User 1 | Trip 18 | Pothole | 4 | 0 | 0 | 4 | 4 | 9.0 | 10.0 | –1.0 | 1.00 |
| **Rep 6** | User 1 | Trip 20 | Sudden Braking | 3 | 0 | 0 | 0 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 7** | User 1 | Trip 22 | Pothole | 4 | 0 | 0 | 1 | 1 | 9.0 | 6.0 | +3.0 | 9.00 |
| **Rep 8** | User 1 | Trip 25 | Pothole | 5 | 0 | 0 | 8 | 8 | 12.0 | 12.0 | 0.0 | 0.00 |
| **Rep 9** | User 1 | Trip 26 | Pothole | 4 | 0 | 0 | 2 | 2 | 9.0 | 7.5 | +1.5 | 2.25 |
| **Rep 10** | User 2 | Trip 2 | Speeding | 3 | 0 | 0 | 0 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 11** | User 2 | Trip 2 | Speeding | 3 | 0 | 0 | 0 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Rep 12** | User 2 | Trip 2 | Speeding | 3 | 0 | 0 | 0 | 0 | 4.0 | 3.0 | +1.0 | 1.00 |
| **Total** | | | | | | | | | | | | **$\sum d^2 = 101.50$** |

#### Tied-Rank Structure:
- **Severity ($X$)**:
  - Value 2 (1 item): Rank 1.0
  - Value 3 (5 items: Reps 1, 6, 10, 11, 12): Ranks 2, 3, 4, 5, 6 $\rightarrow$ Average Rank = $\frac{2+3+4+5+6}{5} = \mathbf{4.0}$
  - Value 4 (5 items: Reps 3, 4, 5, 7, 9): Ranks 7, 8, 9, 10, 11 $\rightarrow$ Average Rank = $\frac{7+8+9+10+11}{5} = \mathbf{9.0}$
  - Value 5 (1 item: Rep 8): Rank 12.0
- **Sensor Events ($Y$)**:
  - Value 0 (5 items: Reps 1, 6, 10, 11, 12): Ranks 1, 2, 3, 4, 5 $\rightarrow$ Average Rank = $\frac{1+2+3+4+5}{5} = \mathbf{3.0}$
  - Value 1 (1 item: Rep 7): Rank 6.0
  - Value 2 (2 items: Reps 3, 9): Ranks 7, 8 $\rightarrow$ Average Rank = $\frac{7+8}{2} = \mathbf{7.5}$
  - Value 4 (3 items: Reps 2, 4, 5): Ranks 9, 10, 11 $\rightarrow$ Average Rank = $\frac{9+10+11}{3} = \mathbf{10.0}$
  - Value 8 (1 item: Rep 8): Rank 12.0

---

### Part 3. Statistical Calculations

#### Analysis A: Report-Level Exploratory Spearman Correlation ($n = 12$)

Because both variables contain tied ranks in the 12 observations, the unadjusted shortcut formula $\rho = 1 - 6\sum d^2 / (n(n^2-1)) = 0.6451$ is mathematically invalid because it overstates correlation by failing to correct for reduced rank variance. Applying the exact Pearson product-moment formulation on fractional ranks (Zar, 2010 [60]):
$$\rho_s = \frac{S_{xy}}{\sqrt{S_{xx} S_{yy}}}$$
where the rank deviations and cross-products calculated from the 12 observations are:
- Sum of squared rank differences: $\sum d_i^2 = \mathbf{101.50}$
- Corrected rank sum of squares for severity ($X$): $S_{xx} = \sum (R_{X_i} - \bar{R}_X)^2 = \mathbf{123.0}$
- Corrected rank sum of squares for sensor events ($Y$): $S_{yy} = \sum (R_{Y_i} - \bar{R}_Y)^2 = \mathbf{130.5}$
- Rank cross-product: $S_{xy} = \sum (R_{X_i} - \bar{R}_X)(R_{Y_i} - \bar{R}_Y) = \mathbf{76.0}$
- **Exact Tied-Rank Correlation**:
  $$\rho_s = \frac{76.0}{\sqrt{123.0 \times 130.5}} = \frac{76.0}{\sqrt{16051.5}} = \frac{76.0}{126.6945} = \mathbf{0.5999} \quad (\approx \mathbf{+0.60})$$

**Hypothesis Testing ($H_0: \rho = 0$ vs. $H_1: \rho \neq 0$):**
$$t = \rho_s \sqrt{\frac{n - 2}{1 - \rho_s^2}} = 0.5999 \times \sqrt{\frac{10}{1 - (0.5999)^2}} = 0.5999 \times \sqrt{\frac{10}{0.6401}} = 0.5999 \times 3.9525 = \mathbf{2.37}$$
- Degrees of freedom: $df = n - 2 = 10$
- Critical value ($t_{\text{crit}}$) at $\alpha = 0.05$ (two-tailed): $2.228$
- Exact two-tailed $p$-value: **$p \approx 0.039$** (Nominally significant at $\alpha = 0.05$; exploratory)

---

#### Analysis B: Trip-Level Aggregated Conservative Correlation ($N = 9$ Unique Trips)

Because multiple reports originated from the same trips (Reports 4 and 5 from Trip 18; Reports 10, 11, and 12 from User 2 on Trip 2), reports were aggregated to unique trips to enforce unit independence:
- **Aggregation Rule**: For trips with multiple reports, reported severity ratings are averaged ($X_{\text{trip}} = \frac{1}{k}\sum X_i$), while trip-level sensor events ($Y_{\text{trip}}$) are taken directly from the trip record.

**Table G-2. Aggregated Unique Trip Dataset ($N = 9$)**

| Trip ID | User ID | Mean Reported Severity | Total Sensor Events | Tied Rank ($R_X$) | Tied Rank ($R_Y$) | Difference ($d$) | Squared Diff ($d^2$) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Trip 1 | User 1 | 3.00 | 0 | 3.0 | 2.0 | +1.0 | 1.00 |
| Trip 13 | User 1 | 2.00 | 4 | 1.0 | 7.5 | –6.5 | 42.25 |
| Trip 16 | User 1 | 4.00 | 2 | 6.5 | 5.5 | +1.0 | 1.00 |
| Trip 18 | User 1 | 4.00 (avg of 2) | 4 | 6.5 | 7.5 | –1.0 | 1.00 |
| Trip 20 | User 1 | 3.00 | 0 | 3.0 | 2.0 | +1.0 | 1.00 |
| Trip 22 | User 1 | 4.00 | 1 | 6.5 | 4.0 | +2.5 | 6.25 |
| Trip 25 | User 1 | 5.00 | 8 | 9.0 | 9.0 | 0.0 | 0.00 |
| Trip 26 | User 1 | 4.00 | 2 | 6.5 | 5.5 | +1.0 | 1.00 |
| Trip 2 | User 2 | 3.00 (avg of 3) | 0 | 3.0 | 2.0 | +1.0 | 1.00 |
| **Total** | | | | | | | **$\sum d^2 = 54.50$** |

**Trip-Level Intermediate Statistics and Correlation:**
- Sum of squared rank differences: $\sum d^2 = \mathbf{54.50}$
- Rank sum of squares for severity ($X$): $S_{xx} = \mathbf{53.0}$
- Rank sum of squares for sensor events ($Y$): $S_{yy} = \mathbf{57.0}$
- Rank cross-product: $S_{xy} = \mathbf{27.75}$
- **Exact Tied-Rank Correlation**:
  $$\rho_s = \frac{27.75}{\sqrt{53.0 \times 57.0}} = \frac{27.75}{\sqrt{3021.0}} = \frac{27.75}{54.9636} = \mathbf{0.5049} \quad (\approx \mathbf{+0.50})$$
- Test statistic ($t$-approximation): $t = 0.5049 \times \sqrt{\frac{7}{1 - (0.5049)^2}} = \mathbf{1.55}, df = 7$
- Critical value ($t_{\text{crit}}$) at $\alpha = 0.05$ (two-tailed): $2.365$
- Two-tailed $p$-value: **$p \approx 0.165$** (**Not statistically significant** at $\alpha = 0.05$)

---

### Part 4. Scope, Methodological Boundaries, and Mandatory Limitations

To establish full academic compliance and empirical transparency, the research proponents state the exact boundaries and data limitations of the SOP 2 analyses honestly:

1. **Definition of Correlated Variables**:
   - **Sensor Variable ($Y$)**: Trip-level count of physical driving anomalies, defined as $Y = \text{speedingCount} + \text{brakingCount} + \text{turningCount}$ accumulated over the entire trip duration.
   - **Passenger Variable ($X$)**: The commuter's reported incident-severity rating, an ordinal evaluation submitted on a 5-point scale (1 = Minor to 5 = Severe).
   - *Evidentiary Framing*: Interpreted strictly as an **exploratory association in the matched sample**, not as proof that sensor anomalies predict incident severity.

2. **Contrast of Report-Level vs. Trip-Level Results**:
   - Report-level Spearman correlation is nominally significant at $\alpha = 0.05$ ($n = 12, \rho_s = +0.60, t = 2.37, p = 0.039$).
   - Trip-level conservative aggregation is **not statistically significant** ($N = 9, \rho_s = +0.50, t = 1.55, p = 0.165$).

3. **Four Mandatory Methodological Limitations**:
   - *Small Sample Size*: Only 12 matched reports across 9 unique trips, providing limited statistical power.
   - *Dominant Passenger and User Clustering*: Contributed by only two users (`User 1` contributed 9 of 12 reports, or 75.0%), violating independence assumptions.
   - *Unmatched Records*: Out of 124 passenger hazard reports in the broader Firebase database, **112 records (90.3%) could not be paired** with continuous onboard sensor telemetry (89 submitted outside active trips without trip tracking, 23 on unarchived/unsynced client devices).
   - *Absence of Incident-Specific Sensor Windows*: Sensor counts represent aggregates across the full trip rather than localized telemetry in a narrow time/distance window (e.g., $\pm 5$ min, $\pm 150$ m) around the reported incident pin.

4. **Human Inter-Rater Reliability (Not Completed)**:
   - *Requirement*: Suitable paired, independent-rater classifications where two or more raters independently assess the same physical transit incidents under a dual-blind protocol.
   - *Status*: The available study records contain primary commuter submissions (Rater A = "Hazard Present") and asynchronous community moderation, but do not contain paired independent-rater classifications for the same incidents.
   - *Honest Disclosure*: Human inter-rater reliability was **not measured or completed**. Cohen's kappa belongs strictly to SOP 1 detector concordance and is not claimed as an inter-rater reliability statistic for SOP 2.

5. **Numerical Effect of Reporting Frequency on Adaptive Credibility (SOP 2.1 — Unverified)**:
   - *Limitation*: The available study records (`saferide_trust_metrics.csv`) provide only a static snapshot of final aggregated report totals and trust values at the time of export. They **do not contain a complete history of initial trust values, subsequent trust-score changes, or a report-by-report calculation log**.
   - *Honest Disclosure*: The numerical effect of reporting frequency on adaptive credibility scores **cannot be independently verified** from the available records.

6. **Numerical Effect of Sensor Conformity on Adaptive Credibility (SOP 2.2 — Unverified)**:
   - *Methodological Principle*: In public transit crowdsourcing, the **absence of a matching sensor event should not automatically invalidate a report**. Many legitimate commuter-reported hazards (e.g., roadway potholes traversed slowly, driver verbal discourtesy, minor overloading, vehicle mechanical defects) do not generate physical kinematic threshold exceedances.
   - *Limitation*: The available files do not provide a complete report-by-report audit record showing how each sensor concordance or discordance result dynamically altered the user's trust score over time.
   - *Honest Disclosure*: The direct numerical effect of sensor conformity on adaptive credibility **remains unverified** from the available study records.

---

### Part 5. Sensitivity Analysis: Dominant Passenger Exclusion and Sample Fragility

To evaluate the stability of the matched correlation and assess the influence of dominant passenger concentration, four comparative sensitivity models were executed:

**Table G-3. Sensitivity Analysis of Matched Sensor-Report Correlations**

| Analysis Model | Matching Pipeline & Condition | Sample Size ($n$) | Spearman Correlation ($\rho_s$) | Test Statistic ($t$, $df$) | Significance ($p$-value) | Robustness Finding |
|---|---|:---:|:---:|:---:|:---:|---|
| **Model 1: Native SQLite (PRIMARY)** | Same-passenger SQLite `.db` deterministic match | **12** | **+0.5999** ($\approx +0.60$) | $t = 2.37, df = 10$ | **$p = 0.039$** | Primary validated exploratory finding; anchored by Trip 25 ($X=5, Y=8$). |
| **Model 2: Firebase Cross-Matched** | Firebase reports cross-matched to `.db` trips | **11** | **–0.8864** | $t = -5.74, df = 9$ | **$p = 0.0003$** | Heavily concentrated: 10 of 11 reports from user `5y0AF7w3`. |
| **Model 3: Dominant Passenger Excluded** | Firebase cross-match excluding user `5y0AF7w3` | **1** | **Undefined** | — | — | **Sample collapses**: With only 1 case remaining, correlation is mathematically impossible. |
| **Model 4: Minority Passenger Excluded** | Firebase cross-match excluding user `59C62FDg` | **10** | **–0.9129** | $t = -6.34, df = 8$ | **$p = 0.0002$** | Reflects single-user idiosyncratic negative correlation profile. |

*Sensitivity Interpretation*:
The sensitivity tests confirm that any correlation between passenger severity and sensor anomalies in SafeRide is **highly fragile and dependent on individual user concentration**. Excluding the dominant passenger in Model 2 completely destroys the sample ($n=1$), while in Model 1, User 1 represents 75% of observations. This reinforces the methodological mandate that SOP 2 results must be framed strictly as an **exploratory association in the matched sample**, not generalizable proof that sensor anomalies predict incident severity.

**Recommended Conclusion for SOP 2**:
The matched native SQLite sample showed a positive exploratory association between reported incident severity and trip-level sensor-event counts ($\rho_s = +0.60, p = 0.039$). However, the small sample ($n=12$), repeated observations, contributor concentration (2 users), and use of trip-wide rather than incident-specific sensor data prevent a general conclusion that higher sensor-event counts reliably correspond to more severe passenger-reported incidents across the commuter population. The credibility mechanism is implemented in the system, but its individual numerical contributions cannot be independently reconstructed from static snapshots alone.

---

### Part 6. Summary Compliance Status Matrix (SOP 2)

| SOP 2 Dimension / Claim | Status | Empirical Rationale & Honest Limitation |
|---|:---:|---|
| **Preliminary positive monotonic association** (Sensor anomaly frequency vs. reported severity) | ✅ **Exploratory** | Supported at report level ($n = 12, \rho_s = +0.60, p = 0.039$); non-significant at trip level ($N = 9, \rho_s = +0.50, p = 0.165$). |
| **Reproducibility of matched dataset** | ✅ **Verified** | 12 matched records reproducible from `export data/SR/` SQLite databases using deterministic tripId linkage rule. |
| **Trip-level correlation statistically significant** | ❌ **Not Significant** | $p = 0.165 > 0.05$; hypothesis of generalizable correlation is not conclusively established. |
| **Sensitivity to dominant passenger** | ⚠️ **Fragile** | Excluding dominant user in cross-pipeline drops $n=11 \rightarrow n=1$, causing correlation calculation to collapse. |
| **Paired independent-rater classifications for inter-rater reliability** | ❌ **Not Completed** | Unavailable in study records; crowdsourcing gathered primary incident submissions without paired dual-blind observers. Limitation honestly stated. |
| **Numerical effect of reporting frequency on adaptive credibility (SOP 2.1)** | ❌ **Unverified** | Available study records do not contain initial trust values, subsequent changes, or report-by-report logs; effect cannot be independently verified. |
| **Numerical effect of sensor conformity on adaptive credibility (SOP 2.2)** | ❌ **Unverified** | Sensor event absence does not invalidate reports; available files lack report-by-report trust change records; direct effect remains unverified. |
| **Findings generalizable across commuter population** | ❌ **Not Generalizable** | Limited to 2 contributing users in matched SQLite telemetry; requires expanded multi-user cohort study. |


