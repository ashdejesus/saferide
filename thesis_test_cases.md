# SafeRide System Test Cases

## A. Simple Cases

| ID | Category | Test Case Description | Test Steps | Expected Outcome | Passed |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-S-001 | Simple | Register a new user account | 1. Open SafeRide.<br>2. Select Register.<br>3. Enter valid account details.<br>4. Submit registration. | A new user account is successfully created and the user can access the system. | |
| TC-S-002 | Simple | Log in using valid credentials | 1. Open SafeRide.<br>2. Enter a registered email and password.<br>3. Select Login. | The user is successfully authenticated and redirected to the dashboard. | |
| TC-S-003 | Simple | Start a trip | 1. Open the Map or Start Trip screen.<br>2. Select the appropriate vehicle type.<br>3. Start the trip. | The trip begins successfully and the system starts recording the user's trip data. | |
| TC-S-004 | Simple | End an active trip | 1. Start an active trip.<br>2. Select End Trip.<br>3. Confirm the action. | The trip ends successfully and the trip data is saved for safety analysis. | |
| TC-S-005 | Simple | View trip safety summary | 1. Complete a trip.<br>2. Open the trip history or trip details. | The system displays the completed trip's route and calculated safety/risk information. | |
| TC-S-006 | Simple | Submit a passenger safety report | 1. Start or access an active trip.<br>2. Open the reporting feature.<br>3. Select a report severity/type.<br>4. Submit the report. | The passenger report is successfully recorded and included in the system's safety analysis. | |
| TC-S-007 | Simple | View community safety information | 1. Open the Map screen.<br>2. View available community safety data or reported incidents. | The system displays available safety information from collected trip and passenger report data. | |

## B. Edge Cases

| ID | Category | Test Case Description | Test Steps | Expected Outcome | Passed |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-E-001 | Edge | Attempt to start a trip without an internet connection | 1. Disable mobile data and Wi-Fi.<br>2. Open SafeRide.<br>3. Attempt to start a trip. | Instead of preventing the trip, the system properly handles the lack of connectivity using its Offline-First architecture. The trip successfully starts recording by saving sensor data and trip states locally to the device's SQLite database without crashing or requiring internet access. | |
| TC-E-002 | Edge | Attempt to start a trip without location permission | 1. Disable location permission for SafeRide.<br>2. Open the Start Trip screen.<br>3. Attempt to start a trip. | The system requests location permission or prevents trip recording until location access is enabled. | |
| TC-E-003 | Edge | End a trip immediately after starting | 1. Start a trip.<br>2. End the trip immediately. | The system handles the very short trip without crashing and properly saves or rejects the trip according to the system's minimum data requirements. | |
| TC-E-004 | Edge | Submit a report with incomplete information | 1. Open the passenger report form.<br>2. Leave required fields empty.<br>3. Attempt to submit. | The system prevents submission and identifies the missing required information. | |
| TC-E-005 | Edge | Submit multiple reports in a short period | 1. Start a trip.<br>2. Submit several reports within a short period.<br>3. Observe the system response. | The system processes the reports correctly and prevents unintended duplicate or invalid submissions where applicable. | |
| TC-E-006 | Edge | Use the system with weak or unstable internet connection | 1. Start SafeRide with an unstable connection.<br>2. Attempt to load the map or record a trip.<br>3. Observe the system behavior. | The system handles connection interruptions without crashing. Map tiles or community trip data may be delayed or fail to load properly. The system should provide appropriate feedback regarding the unstable connection and prevent data corruption or duplicate records. | Passed |

## C. Complex Cases

| ID | Category | Test Case Description | Test Steps | Expected Outcome | Passed |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-C-001 | Complex | Vehicle and Environmental Context Adjustment | 1. Run `dart demo_algorithm.dart` in the terminal.<br>2. In Phase 1, select Vehicle 2 (Bus).<br>3. In Phase 2, enter Road Condition 0.2, Traffic Density 0.8, and Environmental Noise 0.9.<br>4. Observe the contextual adjustment and dynamically adjusted thresholds. | The system identifies the selected vehicle as a Bus with a multiplier of 1.20, calculates the Contextual Adjustment Multiplier, and dynamically adjusts the thresholds for speeding, braking, and turning based on the vehicle and environmental conditions. | |
| TC-C-002 | Complex | Sliding Window Processing and Event Detection | 1. Complete Phases 1 and 2.<br>2. In Phase 3, input the following sensor data:<br>• Second 1: Speed 40, Z-Accel 9.8, Z-Gyro 0<br>• Second 2: Speed 45, Z-Accel 9.8, Z-Gyro 5.0<br>• Second 3: Speed 10, Z-Accel 14.5, Z-Gyro 0<br>3. Observe the Phase 4 output. | The system calculates the Window Average Speed, identifies the maximum deceleration from the change in speed, and determines the maximum angular velocity. Based on the adjusted thresholds, the system detects and displays the appropriate events, such as harsh braking, sharp turning, and road impact or pothole events. | |
| TC-C-003 | Complex | Sensor Risk Scoring Formulation (Rₛₑₙₛ) | 1. Complete Phase 4 event detection.<br>2. Observe the Phase 5 output in the terminal. | The system applies the defined event weights to the detected sensor events and incorporates the contextual adjustment to calculate the Sensor Risk Score (Rₛₑₙₛ) within the expected 0.0–1.0 risk range. | |
| TC-C-004 | Complex | Passenger Crowdsourcing and Trust Weighting (Rᵣₑₚ) | 1. Continue to Phase 6.<br>2. Enter `y` to indicate a passenger report.<br>3. Enter Rating 5 (Dangerous).<br>4. Enter Trust Score 0.85.<br>5. Observe the passenger crowdsourcing output. | The system calculates the Report Risk Score (Rᵣₑₚ) and adjusts the report's influence according to the passenger's trust score of 0.85. The system also calculates the Sensor Data Weighting (λ) based on the available sensor and passenger report data. | |
| TC-C-005 | Complex | Final Nonlinear Fusion and Discrepancy Penalty | 1. Complete the calculation of Rₛₑₙₛ and Rᵣₑₚ.<br>2. Observe the Phase 7 output at the end of the terminal execution. | The system compares the sensor-based and passenger-reported risk values. When a significant discrepancy is detected, the system applies the defined discrepancy penalty. It then calculates the Final Trip Risk Score (Rₜᵣᵢₚ) and converts the result into the final Safety Score on a 0–100 scale. | |
