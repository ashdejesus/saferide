# APPENDIX G: SOP 2 MATCHED REPORTS, SENSOR COUNTS, AND RANK CALCULATIONS

This appendix provides the complete dataset, rank assignments, and comparative statistical calculations evaluating the monotonic relationship between crowd-reported hazard severity and sensor-detected driving anomalies (SOP 2).

---

### Part 1. Distinction Between Passenger-Report Datasets

A critical methodological distinction exists between the two passenger-report datasets accumulated by SafeRide:
1. **Broader Conformity and Trust Dataset ($N = 114$ reports)**:
   - Stored in `passenger_reports.csv` across all system testing phases in Laguna.
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

When datasets contain tied ranks, the standard shortcut formula yields an unadjusted estimate:
$$\rho_{\text{shortcut}} = 1 - \frac{6 \sum d^2}{n(n^2 - 1)} = 1 - \frac{6 \times 101.50}{12 \times (144 - 1)} = 1 - \frac{609.0}{1,716} = \mathbf{0.6451}$$

The exact Pearson correlation evaluated directly on tied ranks (Zar, 2010 [60]) corrects for tied variance:
$$\text{Cov}(R_X, R_Y) = 7.1818, \quad s_{R_X} = 3.6556, \quad s_{R_Y} = 3.2753$$
$$\rho_s = \frac{\sum (R_X - \bar{R}_X)(R_Y - \bar{R}_Y)}{\sqrt{\sum (R_X - \bar{R}_X)^2 \sum (R_Y - \bar{R}_Y)^2}} = \mathbf{0.5999} \quad (\approx \mathbf{+0.60})$$

**Hypothesis Testing ($H_0: \rho = 0$ vs. $H_1: \rho \neq 0$):**
$$t = \rho_s \sqrt{\frac{n - 2}{1 - \rho_s^2}} = 0.5999 \times \sqrt{\frac{10}{1 - (0.5999)^2}} = 0.5999 \times \sqrt{\frac{10}{0.6401}} = 0.5999 \times 3.9525 = \mathbf{2.37}$$
- Degrees of freedom: $df = n - 2 = 10$
- Critical value ($t_{\text{crit}}$) at $\alpha = 0.05$ (two-tailed): $2.228$
- Exact two-tailed $p$-value: **$p \approx 0.039$** (Statistically significant at $\alpha = 0.05$)

---

#### Analysis B: Trip-Level Aggregated Conservative Correlation ($N = 9$ Unique Trips)

Because Reports 4 and 5 originate from Trip 18, and Reports 10, 11, and 12 represent repeated submissions by User 2 on Trip 2, individual reports violate the assumption of independent observations. To provide a conservative benchmark, reports were aggregated by unique trip (averaging multiple reported severities per trip):

**Table G-2. Aggregated Unique Trip Dataset ($N = 9$)**

| Trip ID | User ID | Mean Reported Severity | Total Sensor Events | Rank (Severity) | Rank (Events) | $d$ | $d^2$ |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Trip 1 | User 1 | 3.00 | 0 | 2.5 | 2.0 | +0.5 | 0.25 |
| Trip 13 | User 1 | 2.00 | 4 | 1.0 | 7.5 | –6.5 | 42.25 |
| Trip 16 | User 1 | 4.00 | 2 | 6.5 | 5.5 | +1.0 | 1.00 |
| Trip 18 | User 1 | 4.00 (avg of 2) | 4 | 6.5 | 7.5 | –1.0 | 1.00 |
| Trip 20 | User 1 | 3.00 | 0 | 2.5 | 2.0 | +0.5 | 0.25 |
| Trip 22 | User 1 | 4.00 | 1 | 6.5 | 4.0 | +2.5 | 6.25 |
| Trip 25 | User 1 | 5.00 | 8 | 9.0 | 9.0 | 0.0 | 0.00 |
| Trip 26 | User 1 | 4.00 | 2 | 6.5 | 5.5 | +1.0 | 1.00 |
| Trip 2 | User 2 | 3.00 (avg of 3) | 0 | 2.5 | 2.0 | +0.5 | 0.25 |
| **Total** | | | | | | | **$\sum d^2 = 52.25$** |

**Trip-Level Statistical Metrics:**
- Tied-rank Spearman correlation: **$\rho_s = +0.5049$** ($\approx \mathbf{+0.50}$)
- Test statistic: $t = 0.5049 \times \sqrt{\frac{7}{1 - (0.5049)^2}} = 0.5049 \times \sqrt{\frac{7}{0.7451}} = 0.5049 \times 3.0651 = \mathbf{1.55}$
- Degrees of freedom: $df = 7$
- Critical value ($t_{\text{crit}}$) at $\alpha = 0.05$ (two-tailed): $2.365$
- Two-tailed $p$-value: **$p \approx 0.165$** (**Not statistically significant** at $\alpha = 0.05$)

---

### Part 4. Summary and Evidentiary Conclusion

1. **Dual-Analysis Reporting**:
   - **Matched reports ($n = 12$)**: $\rho_s = +0.60, p = 0.039$ (statistically significant).
   - **Aggregated unique trips ($N = 9$)**: $\rho_s = +0.50, p = 0.165$ (non-significant).
2. **Conservative Interpretation**:
   The report-level association shows preliminary convergent validity between commuter hazard ratings and physical sensor counts. However, because the trip-level correlation is non-significant due to small sample size and user clustering, the monotonic relationship is **exploratory and not conclusively established**.
