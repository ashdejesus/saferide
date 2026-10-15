# APPENDIX H: SOP 3 TRIP DATASET, ROUTE ACCOUNTING, AND PAIRED WILCOXON CALCULATIONS

This appendix documents the trip-level risk scoring dataset, route corridor accounting across the complete 150-trip database export, and step-by-step mathematical derivations for the Wilcoxon signed-rank test and 150-trip Spearman correlation (SOP 3).

---

### Part 1. Paired Risk Score Dataset and Wilcoxon Signed-Rank Test

To evaluate whether SafeRide's multi-source fusion algorithm systematically differentiates the final composite trip risk score ($R_{\text{trip}}$) from the baseline sensor-only risk component ($R_{\text{sens}}$), a paired non-parametric analysis was conducted on the nine unique reported trips from SOP 2.

#### Table H-1. Paired Sensor vs. Composite Risk Values ($N = 9$)

| Trip Identifier | Stored Sensor Counts ($S, B, T$) | Normalized Sensor Risk ($R_{\text{sens}}$) | Stored Composite Risk ($R_{\text{trip}} = \frac{\text{risk\_score}}{100}$) | Paired Difference ($D = R_{\text{trip}} - R_{\text{sens}}$) | Absolute Difference ($|D|$) | Rank of $|D|$ | Signed Rank |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Trip 1** | $S=0, B=0, T=0$ | 0.0000 | 0.0000 | 0.0000 | 0.0000 | Tied zero | Dropped |
| **Trip 13** | $S=0, B=0, T=4$ | 0.0023 | 0.0421 | +0.0398 | 0.0398 | 5.0 | +5.0 |
| **Trip 16** | $S=0, B=0, T=2$ | 0.0129 | 0.1499 | +0.1370 | 0.1370 | 7.0 | +7.0 |
| **Trip 18** | $S=0, B=0, T=4$ | 0.0381 | 0.1142 | +0.0761 | 0.0761 | 6.0 | +6.0 |
| **Trip 20** | $S=0, B=0, T=0$ | 0.0000 | 0.0000 | 0.0000 | 0.0000 | Tied zero | Dropped |
| **Trip 22** | $S=0, B=0, T=1$ | 0.0007 | 0.0224 | +0.0217 | 0.0217 | 3.0 | +3.0 |
| **Trip 25** | $S=0, B=0, T=8$ | 0.0005 | 0.0040 | +0.0035 | 0.0035 | 1.0 | +1.0 |
| **Trip 26** | $S=0, B=0, T=2$ | 0.0008 | 0.0343 | +0.0335 | 0.0335 | 4.0 | +4.0 |
| **User2-Trip2** | $S=0, B=0, T=0$ | 0.0000 | 0.0152 | +0.0152 | 0.0152 | 2.0 | +2.0 |

#### Step-by-Step Wilcoxon Derivation:
1. **Handling Zero Differences**:
   Trips 1 and 20 had zero differences ($D = 0.0000$) due to zero sensor anomalies and zero passenger hazard severity. In accordance with standard non-parametric procedure (Wilcoxon, 1945 [63]), zero-difference pairs are excluded from ranking, leaving **$N_{\text{diff}} = 7$ non-zero pairs**.
2. **Ranking Absolute Differences ($|D|$)**:
   - $0.0035 \rightarrow \text{Rank } 1$
   - $0.0152 \rightarrow \text{Rank } 2$
   - $0.0217 \rightarrow \text{Rank } 3$
   - $0.0335 \rightarrow \text{Rank } 4$ (Trip 26)
   - $0.0398 \rightarrow \text{Rank } 5$ (Trip 13)
   - $0.0761 \rightarrow \text{Rank } 6$ (Trip 18)
   - $0.1370 \rightarrow \text{Rank } 7$ (Trip 16)
3. **Signed Rank Sums**:
   - All 7 non-zero differences were strictly positive ($R_{\text{trip}} > R_{\text{sens}}$).
   - Sum of positive ranks: $W^+ = 1 + 2 + 3 + 4 + 5 + 6 + 7 = \mathbf{28.0}$
   - Sum of negative ranks: $W^- = \mathbf{0.0}$
   - Test statistic: $W = \min(W^+, W^-) = \mathbf{0.0}$
4. **Exact Two-Tailed Significance**:
   Under the null hypothesis $H_0$ that paired differences are symmetrically distributed around zero, the probability of obtaining all positive ranks for $N_{\text{diff}} = 7$ is:
   $$p = 2 \times \left(\frac{1}{2}\right)^7 = 2 \times \frac{1}{128} = \frac{2}{128} = \mathbf{0.015625} \quad (\approx \mathbf{0.016})$$
   Because $p = 0.016 < 0.05$, the null hypothesis is rejected.

#### Critical Evidentiary Distinction:
- **What this result establishes**: The Wilcoxon test confirms a **statistically significant systematic elevation** of the calculated risk score when passenger reports are integrated through adaptive weighting and the discrepancy penalty. Passenger reports contribute non-redundant variance to the composite index.
- **What this result does NOT establish**: The test does **not prove that the composite score is more accurate against real-world road safety**. It evaluates algorithmic behavior and score shift under multi-source fusion, not empirical ground-truth validity against independent collision statistics.

---

### Part 2. Complete 150-Trip Database Accounting and Correlation

The cumulative SQLite database archive contains **150 logged trips** gathered across system testing in Laguna.

#### Table H-2. Trip and Route Dataset Accounting

| Category / Stratum | Record Count ($N$) | Description and Operational Context |
|---|:---:|:---|
| **Primary Transit Corridors** | **24 trips** | Major municipal arteries and controlled loop corridors: <br>• Cabuyao City Loop (120 Manila S Rd): 14 trips (Mean Risk = 1.05)<br>• Calamba–Los Baños Highway Corridor: 2 trips (Mean Risk = 16.64)<br>• Calamba City (Crossing to Mayapa): 1 trip (Risk = 45.50)<br>• Cabuyao City (Pulo to Banlic): 1 trip (Risk = 18.20)<br>• Sta Rosa (Balibago to Nuvali): 1 trip (Risk = 38.60)<br>• Biñan City (Pavilion to Olivarez): 1 trip (Risk = 52.40)<br>• Cross-city corridors (Cabuyao to Sta Rosa, Manatid loops): 4 trips |
| **Other Named Local Transit Runs** | **22 trips** | Specific local collector and retesting runs: <br>• Retesting runs (PL-DZ-01, DZ-PL-02, SALA-BNY-04, BNY-PNC-05, PNC-BNY-06): 5 trips<br>• Banaybanay–Sala runs (tagged `BNY-SALA-03`): 3 trips (Mean Risk = 4.44)<br>• Pulo–Banaybanay and specific street address pickups: 14 trips |
| **Subtotal: Named / Geocoded Trips** | **46 trips** | All trips with explicit corridor names, route tags, or reverse-geocoded road segments |
| **Unassigned / System Test Segments** | **104 trips** | Client database records without formal corridor tags; internal sensor calibration tests, stationary tests, and short GPS tracking check segments |
| **Total Recorded Trips in SQLite Archive** | **150 trips** | Complete database population analyzed for SOP 3 scale evaluation |

#### Table H-3. Clarification of Route BNY-SALA-03 Database Records

| DB Source File | Internal Trip ID | Timestamp | Logged Duration | Speeding | Braking | Turning | Risk Score | Safety Score | Operational Classification |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| `saferide_user_5y0AF7w36FZV...db` | Trip 207 | 2026-10-05T16:54:43 | 459 s | 0 | 0 | 2 | 13.06 | 86.94 | **Evaluated Field Retesting Trip** (SOP 1 / Table 7) |
| `saferide_user_5y0AF7w36FZV...db` | Trip 235 | 2026-10-07T12:50:08 | 269 s | 0 | 0 | 0 | 0.00 | 100.00 | Subsequent technical test run under route tag |
| `saferide_user_5y0AF7w36FZV...db` | Trip 238 | 2026-10-07T12:54:55 | 415 s | 0 | 0 | 1 | 0.25 | 99.75 | Subsequent technical test run under route tag |
| **Route Tag Archive Mean** | | | | | | | **4.44** | **95.56** | **Database Archive Average** ($N = 3$) |

*Clarification of Aggregation Methods*:
1. **Chapter IV Table 8 (Evaluated Commuter Field Retesting Corridor)**: Table 8 reports the commuter transit corridor average across the two evaluated field retesting trips: outbound Trip 207 (Risk = 13.06) and inbound Trip 220 (Risk = 0.49), yielding an evaluated corridor mean risk of $(13.06 + 0.49) / 2 = \mathbf{6.78}$ (Safety Score = **93.22**).
2. **Table H-3 (Historical Database Archive Accounting)**: Separately, Table H-3 accounts for all three records carrying the specific database tag `BNY-SALA-03` in the broader SQLite archive (Trip 207: 13.06, Trip 235: 0.00, Trip 238: 0.25), yielding an aggregate database mean of $(13.06 + 0.00 + 0.25) / 3 = \mathbf{4.44}$ (Safety Score = **95.56**). Both metrics are documented and traceable to their respective datasets.

---

### Part 3. 150-Trip Spearman Correlation Calculation

Across all 150 trip records, Spearman's rank correlation was computed between **total sensor-event counts** ($X = \text{speeding} + \text{braking} + \text{turning}$) and **composite trip risk scores** ($Y = \text{risk\_score}$):
- Sample size: $N = 150$
- Tied-rank Spearman correlation: **$\rho_s = +0.6146$**
- Test statistic:
  $$t = \rho_s \sqrt{\frac{N - 2}{1 - \rho_s^2}} = 0.6146 \times \sqrt{\frac{148}{1 - (0.6146)^2}} = 0.6146 \times \sqrt{\frac{148}{0.6223}} = 0.6146 \times 15.4211 = \mathbf{9.48}$$
- Degrees of freedom: $df = 148$
- Significance: **$p < 0.0001$**

This demonstrates that total sensor event count remains the primary, highly significant driver of the composite risk score across the full 150-trip database population.
