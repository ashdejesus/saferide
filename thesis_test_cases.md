# SafeRide System Test Cases

## TC-001 — Register a new passenger account using valid information

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-001 |
| **Test Case Name** | Register a new passenger account using valid information |
| **Module** | User Registration |
| **Precondition** | The user does not have an existing SafeRide account. |
| **Test Data** | Name: `Juan Dela Cruz`<br>Email: `juan@example.com`<br>Password: `SafeRide2026!` |
| **Test Steps** | 1. Open SafeRide.<br>2. Select **Register**.<br>3. Enter valid user information.<br>4. Submit the form. |
| **Expected Result** | The system successfully creates the account and redirects the user to the login or dashboard page. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-002 — Register using an already registered email

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-002 |
| **Test Case Name** | Register using an already registered email |
| **Module** | User Registration |
| **Precondition** | A user account with the email already exists in the system. |
| **Test Data** | Email: `juan@example.com` (Already in DB) |
| **Test Steps** | 1. Open the registration page.<br>2. Enter an existing email address.<br>3. Submit the form. |
| **Expected Result** | The system rejects the registration and displays an appropriate error message. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-003 — Log in using valid account credentials

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-003 |
| **Test Case Name** | Log in using valid account credentials |
| **Module** | User Login |
| **Precondition** | The user has an existing SafeRide account. |
| **Test Data** | Email: `juan@example.com`<br>Password: `SafeRide2026!` |
| **Test Steps** | 1. Enter a registered email and password.<br>2. Select **Login**. |
| **Expected Result** | The system authenticates the user and displays the passenger dashboard. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-004 — Log in using invalid credentials

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-004 |
| **Test Case Name** | Log in using invalid credentials |
| **Module** | User Login |
| **Precondition** | The user has an existing SafeRide account. |
| **Test Data** | Email: `juan@example.com`<br>Password: `WrongPass123` |
| **Test Steps** | 1. Enter an incorrect email or password.<br>2. Select **Login**. |
| **Expected Result** | The system denies access and displays an authentication error message. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-005 — Start a trip using a supported public transportation vehicle

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-005 |
| **Test Case Name** | Start a trip using a supported public transportation vehicle |
| **Module** | Trip Recording |
| **Precondition** | The user is logged in and ready to start a trip. |
| **Test Data** | Selected Vehicle: `Jeepney` (Multiplier 1.00) |
| **Test Steps** | 1. Log in.<br>2. Select the vehicle type.<br>3. Select **Start Trip**. |
| **Expected Result** | The system starts trip monitoring and begins collecting GPS, accelerometer, gyroscope, speed, and timestamp data. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-006 — Stop an active trip

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-006 |
| **Test Case Name** | Stop an active trip |
| **Module** | Trip Recording |
| **Precondition** | An active trip is currently being monitored by the system. |
| **Test Data** | Trip ID: `TRP-84920`<br>Action: Tap `End Trip` |
| **Test Steps** | 1. Start a trip.<br>2. Select **End Trip**. |
| **Expected Result** | The system stops sensor collection and saves the trip data to the database. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-007 — Detect vehicle speed using GPS

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-007 |
| **Test Case Name** | Detect vehicle speed using GPS |
| **Module** | GPS Detection |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Target Speed: `35 km/h` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart` in the terminal.<br>2. Select Vehicle Type `1` (Jeepney) and `0.5` for all environmental factors.<br>3. For Second 1, 2, and 3, enter a GPS Speed of `35`, Z-Accel of `9.8`, and Z-Gyro of `0`. |
| **Expected Result** | The simulation console outputs "Calculated Window Average Speed: 35.00 km/h" indicating successful speed extraction. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-008 — Detect sudden deceleration

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-008 |
| **Test Case Name** | Detect sudden deceleration |
| **Module** | Hard Braking Detection |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Initial Speed: `45`, Final Speed: `0` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Select Vehicle `1` and enter `0.5` for all contexts.<br>3. Second 1 Input: Speed `45`, Accel `9.8`, Gyro `0`.<br>4. Second 2 Input: Speed `45`, Accel `9.8`, Gyro `0`.<br>5. Second 3 Input: Speed `0` (Slamming brakes), Accel `9.8`, Gyro `0`. |
| **Expected Result** | The console displays "⚠️ ALERT: Harsh Braking Detected!" because the calculated deceleration threshold was exceeded. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-009 — Detect abrupt acceleration

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-009 |
| **Test Case Name** | Detect abrupt acceleration |
| **Module** | Sudden Acceleration Detection |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Initial Speed: `0`, Final Speed: `40` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Select Vehicle `1` and enter `0.5` for contexts.<br>3. Second 1 Input: Speed `0`, Accel `9.8`, Gyro `0`.<br>4. Second 2 Input: Speed `40` (Sudden acceleration), Accel `9.8`, Gyro `0`.<br>5. Second 3 Input: Speed `40`, Accel `9.8`, Gyro `0`. |
| **Expected Result** | The system correctly logs a massive speed differential into the sliding window metrics. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-010 — Detect sudden direction changes

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-010 |
| **Test Case Name** | Detect sudden direction changes |
| **Module** | Sharp Turning Detection |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Z-Axis Gyro: `6.5 rad/s` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Select Vehicle `1` and enter `0.5` for contexts.<br>3. Second 1 Input: Speed `30`, Accel `9.8`, Gyro `0`.<br>4. Second 2 Input: Speed `30`, Accel `9.8`, Gyro `6.5` (Simulated swerve).<br>5. Second 3 Input: Speed `30`, Accel `9.8`, Gyro `0`. |
| **Expected Result** | The console displays "⚠️ ALERT: Sharp Turning Detected!" because 6.5 rad/s exceeds the adaptive turning threshold. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-011 — Detect vehicle speed above the configured threshold

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-011 |
| **Test Case Name** | Detect vehicle speed above the configured threshold |
| **Module** | Overspeeding Detection |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Target Speed: `65.0 km/h` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Select Vehicle `1` and enter `0.5` for contexts.<br>3. For Second 1, 2, and 3, input Speed `65`, Accel `9.8`, Gyro `0`. |
| **Expected Result** | The console displays "⚠️ ALERT: Overspeeding Detected!" because the average speed (65) exceeds the Jeepney adaptive threshold (56.03). |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-012 — Process continuous sensor data using time windows

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-012 |
| **Test Case Name** | Process continuous sensor data using time windows |
| **Module** | Sliding Window Processing |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Variable Speeds: `30, 45, 10` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Input three completely different speeds sequentially.<br>3. Observe the "Processing Window Metrics" section of the output. |
| **Expected Result** | The system successfully calculates the correct mathematical average speed and the max deceleration deviation across the 3-second window. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-013 — Reduce false detection caused by sensor fluctuations

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-013 |
| **Test Case Name** | Reduce false detection caused by sensor fluctuations |
| **Module** | Noise Filtering |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Fluctuating Speeds: `28, 32, 29` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Input speeds of 28, 32, and 29 to simulate noisy GPS data.<br>3. Observe the window average. |
| **Expected Result** | The algorithm smooths out the peaks, outputting a stable average of 29.66 km/h rather than throwing an immediate alert. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-014 — Distinguish road anomalies from unsafe driving

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-014 |
| **Test Case Name** | Distinguish road anomalies from unsafe driving |
| **Module** | Road Anomaly Handling |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Normal Z-Accel: `9.8 m/s²`, Pothole Z-Accel: `14.5 m/s²` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Select Vehicle `3` (Tricycle) and enter `0.2` for contexts (bad road).<br>3. Second 1 Input: Speed `30`, Accel `9.8`, Gyro `0`.<br>4. Second 2 Input: Speed `30`, Accel `14.5` (hitting a pothole), Gyro `0`.<br>5. Second 3 Input: Speed `30`, Accel `9.8`, Gyro `0`. |
| **Expected Result** | The console displays "⚠️ ALERT: Pothole Impact Detected!" distinguishing a vertical suspension shock from a driving maneuver. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-015 — Submit a valid crowdsourced safety report

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-015 |
| **Test Case Name** | Submit a valid crowdsourced safety report |
| **Module** | Passenger Reporting |
| **Precondition** | A trip has been completed and is available for reporting. |
| **Test Data** | Trip ID: `TRP-84920`<br>Category: `Reckless Driving`<br>Severity: `4 (High Risk)` |
| **Test Steps** | 1. Complete a trip.<br>2. Open the reporting module.<br>3. Select an incident category and severity.<br>4. Submit the report. |
| **Expected Result** | The system validates and stores the report together with the related trip information. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-016 — Submit an incomplete or invalid report

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-016 |
| **Test Case Name** | Submit an incomplete or invalid report |
| **Module** | Passenger Reporting |
| **Precondition** | A trip has been completed and is available for reporting. |
| **Test Data** | Category: `[Empty / Unselected]`<br>Severity: `[Empty / Unselected]` |
| **Test Steps** | 1. Open the reporting module.<br>2. Leave required fields empty.<br>3. Submit the report. |
| **Expected Result** | The system displays a validation message and does not save the incomplete report. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-017 — Assign credibility to a passenger report

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-017 |
| **Test Case Name** | Assign credibility to a passenger report |
| **Module** | Trust-Weighted Crowdsourcing |
| **Precondition** | A trip has been completed and is available for reporting. |
| **Test Data** | Passenger History: `15 valid reports`<br>Calculated Trust Score: `0.92 / 1.0` |
| **Test Steps** | 1. Submit a valid report.<br>2. Process the report using the trust mechanism. |
| **Expected Result** | The system assigns or updates the user's credibility value based on reporting consistency, frequency, and agreement with sensor data. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-018 — Process a report that agrees with sensor data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-018 |
| **Test Case Name** | Process a report that agrees with sensor data |
| **Module** | Trust-Weighted Crowdsourcing |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Passenger Report: `Yes`, Rating: `5`, Trust: `0.8` |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Input sensor data that triggers alerts (e.g., Speed 60, Accel 14.5).<br>3. When asked "Did a passenger submit a report?", type `y`.<br>4. Enter Passenger Rating `5` (Dangerous) to match the dangerous sensors.<br>5. Enter Trust `0.8`. |
| **Expected Result** | The system acknowledges agreement. No discrepancy penalty is added to the final score computation. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-019 — Process a report that conflicts with sensor data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-019 |
| **Test Case Name** | Process a report that conflicts with sensor data |
| **Module** | Trust-Weighted Crowdsourcing |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | Passenger Report: `Yes`, Rating: `1` (Safe), Sensors: (Dangerous) |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Input dangerous sensor data (Speed 65, Z-Gyro 6.5).<br>3. When asked "Did a passenger submit a report?", type `y`.<br>4. Enter Passenger Rating `1` (Passenger lies and says it is safe).<br>5. Enter Trust `0.8`. |
| **Expected Result** | The console displays "Sensor vs Report Discrepancy Penalty: +X.XXXX" proving the system catches and penalizes the false report. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-020 — Generate a risk score from sensor data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-020 |
| **Test Case Name** | Generate a risk score from sensor data |
| **Module** | Trip Risk Scoring |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | N/A |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Complete the sensor inputs.<br>3. When asked about passenger reports, type `n`. |
| **Expected Result** | The console displays the standalone "Calculated Sensor Risk Score ($R_{sens}$)" calculated solely from the IMU and GPS metrics. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-021 — Combine sensor data and passenger reports

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-021 |
| **Test Case Name** | Combine sensor data and passenger reports |
| **Module** | Composite Risk Scoring |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | N/A |
| **Test Steps** | 1. Run `dart demo_algorithm.dart`.<br>2. Complete sensor inputs.<br>3. Submit a passenger report rating.<br>4. Observe the "FINAL NONLINEAR FUSION" section. |
| **Expected Result** | The system outputs an adaptive weight ($\lambda$) and displays how it combines $R_{sens}$ and $R_{rep}$ into the Final Trip Risk Score. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-022 — Generate the final safety score

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-022 |
| **Test Case Name** | Generate the final safety score |
| **Module** | Trip Safety Score |
| **Precondition** | The algorithm simulation script is ready in the terminal. |
| **Test Data** | N/A |
| **Test Steps** | 1. Follow the simulation script to the very end. |
| **Expected Result** | The system linearly transforms the 0.0 - 1.0 Risk Score into a user-friendly 0 - 100 integer Safety Score, displayed at the bottom of the console. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-023 — Generate a safety score for a route

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-023 |
| **Test Case Name** | Generate a safety score for a route |
| **Module** | Route-Level Safety Score |
| **Precondition** | The SafeRide application is active and running. |
| **Test Data** | Route: `Katipunan Ave`<br>Aggregated Trips: `45`<br>Route Score: `72 / 100` |
| **Test Steps** | 1. Collect multiple trip records from the same route.<br>2. Open the route safety information. |
| **Expected Result** | The system aggregates available trip data and generates a route-level safety assessment. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-024 — Display safety information

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-024 |
| **Test Case Name** | Display safety information |
| **Module** | Safety Visualization |
| **Precondition** | The SafeRide application is active and running. |
| **Test Data** | Selected Item: `Trip TRP-84920`<br>Expected Output: `Red Polyline on Map (High Risk), Score = 58` |
| **Test Steps** | 1. Open the safety score or map module.<br>2. Select an available trip or route. |
| **Expected Result** | The system displays the calculated safety score and relevant transportation safety information in the interface. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-025 — Store trip and report data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-025 |
| **Test Case Name** | Store trip and report data |
| **Module** | Database Storage |
| **Precondition** | The system database is accessible. |
| **Test Data** | Database Payload: `{ "tripId": "...", "events": [...], "finalScore": 58 }` |
| **Test Steps** | 1. Complete a trip.<br>2. Submit a report.<br>3. Check the database records. |
| **Expected Result** | The system stores the required sensor, trip, report, and scoring data correctly. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-026 — Retrieve previously recorded trip information

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-026 |
| **Test Case Name** | Retrieve previously recorded trip information |
| **Module** | Data Retrieval |
| **Precondition** | The system database is accessible. |
| **Test Data** | DB Query: `SELECT * FROM trips WHERE user_id = 'U123'` |
| **Test Steps** | 1. Open the safety rating module.<br>2. Select an available trip. |
| **Expected Result** | The system retrieves the associated trip data and displays the calculated safety information. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-027 — Request safety information without recorded trip data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-027 |
| **Test Case Name** | Request safety information without recorded trip data |
| **Module** | No Available Data |
| **Precondition** | The SafeRide application is active and running. |
| **Test Data** | Query Context: `Route ID: R-999 (No Trips Recorded)`<br>Expected Output: `Empty State UI Message` |
| **Test Steps** | 1. Open the safety rating module.<br>2. Select a vehicle or route with no available records. |
| **Expected Result** | The system displays an appropriate notification indicating that no trip data is available. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-028 — Verify captured sensor data

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-028 |
| **Test Case Name** | Verify captured sensor data |
| **Module** | Data Validation |
| **Precondition** | The system database is accessible. |
| **Test Data** | Raw DB Record: `timestamp: 1690000000, speed: 22.5, ax: 0.1, ay: 0.2, az: 9.8` |
| **Test Steps** | 1. Conduct a trip.<br>2. Review the stored sensor records. |
| **Expected Result** | The system captures the required GPS, accelerometer, gyroscope, speed, and timestamp information. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-029 — Continue monitoring during normal trip operation

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-029 |
| **Test Case Name** | Continue monitoring during normal trip operation |
| **Module** | System Reliability |
| **Precondition** | The SafeRide application is active and running. |
| **Test Data** | Continuous Runtime: `45 mins`<br>Data Points Processed: `> 2,700 windows` (No system crash) |
| **Test Steps** | 1. Start a trip.<br>2. Continue traveling through a route. |
| **Expected Result** | The system continuously records and processes data without unexpected termination or data loss. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |

## TC-030 — Process sensor data during real-time monitoring

| Field | Details |
| :--- | :--- |
| **Test Case ID** | TC-030 |
| **Test Case Name** | Process sensor data during real-time monitoring |
| **Module** | Performance Efficiency |
| **Precondition** | The SafeRide application is active and running. |
| **Test Data** | Processing Latency: `< 50ms per sliding window`<br>Event Result: `Real-time Alert Displayed Instantly` |
| **Test Steps** | 1. Start a trip.<br>2. Generate continuous sensor readings.<br>3. Observe system processing. |
| **Expected Result** | The system processes sensor data and detects unsafe events within an acceptable response time without significant delay. |
| **Actual Result** | To be filled during testing |
| **Status** | Pass / Fail |
