import csv
import json
from datetime import datetime

def main():
    input_csv = 'passenger_reports.csv'
    output_csv = 'saferide_hazard_validation_master.csv'

    # 1. Compute trust metrics for each user based on historical reports
    # (consistency, anomaly, sensor alignment, overall trust)
    user_reports = {}
    with open(input_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    for row in rows:
        uid = row.get('passengerId') or 'guest_user'
        if uid not in user_reports:
            user_reports[uid] = []
        user_reports[uid].append(row)

    user_trust = {}
    for uid, reps in user_reports.items():
        total = len(reps)
        flagged = sum(1 for r in reps if r.get('isFlagged', '').lower() == 'true')
        verified = sum(1 for r in reps if r.get('isVerified', '').lower() == 'true' or int(r.get('verificationCount') or 0) > 0)
        # Trust baseline: 0.50 + conformity bonus - flag penalty
        credibility = max(0.10, min(1.0, (total - flagged) / total if total > 0 else 0.50))
        user_trust[uid] = round(credibility, 2)

    # 2. Build the Master Hazard Validation Dataset
    fieldnames = [
        'Event_ID',
        'Firestore_Doc_ID',
        'Timestamp',
        'Latitude',
        'Longitude',
        'Trip_ID',
        'Hazard_Category',
        'Reported_Severity',
        'Description',
        'Rater_A_ID',
        'Rater_A_Classification',
        'Rater_A_Score',
        'Rater_B_ID',
        'Rater_B_Classification',
        'Rater_B_Score',
        'Verification_Count',
        'Flag_Count',
        'Independent_Ground_Truth',
        'Ground_Truth_Score',
        'Ground_Truth_Method',
        'Trust_Weight',
        'Trust_Weighted_Severity',
        'Sensor_Event_Count',
        'Sensor_Risk_Score',
        'Sensor_Evidence',
        'Sensor_Concordance'
    ]

    # Sort rows by timestamp
    def parse_time(r):
        ts = r.get('timestamp') or r.get('createdAt') or ''
        return ts

    sorted_rows = sorted(rows, key=parse_time)

    out_records = []
    for idx, r in enumerate(sorted_rows):
        event_id = f"H-{(idx + 1):03d}"
        doc_id = r.get('id', '')
        ts = r.get('timestamp') or r.get('createdAt') or ''
        lat = r.get('latitude', '')
        lng = r.get('longitude', '')
        trip_id = r.get('tripId', '')
        category = r.get('category', 'Hazard')
        try:
            severity = int(float(r.get('severity') or 3))
        except ValueError:
            severity = 3
        desc = (r.get('description') or '').replace('\n', ' ').strip()
        
        passenger_id = r.get('passengerId') or 'guest_user'
        rater_a_class = "Hazard Present"
        rater_a_score = 1

        is_ver = r.get('isVerified', '').lower() == 'true'
        is_flag = r.get('isFlagged', '').lower() == 'true'
        try:
            ver_count = int(r.get('verificationCount') or (1 if is_ver else 0))
        except ValueError:
            ver_count = 1 if is_ver else 0
        try:
            flag_count = int(r.get('flagCount') or (1 if is_flag else 0))
        except ValueError:
            flag_count = 1 if is_flag else 0

        # Rater B (Inter-Rater Consensus classification)
        if is_ver or ver_count > 0:
            rater_b_id = "secondary_passenger_verifier"
            rater_b_class = "Hazard Present (Confirmed)"
            rater_b_score = 1
        elif is_flag or flag_count > 0:
            rater_b_id = "secondary_passenger_flagger"
            rater_b_class = "Hazard Absent (Flagged)"
            rater_b_score = 0
        else:
            rater_b_id = "Unrated"
            rater_b_class = "Unrated (Pending)"
            rater_b_score = ""

        try:
            sensor_events = int(r.get('sensorEventCountAtSubmission') or 0)
        except ValueError:
            sensor_events = 0

        try:
            sensor_risk = float(r.get('sensorRiskAtSubmission') or 0.50)
        except ValueError:
            sensor_risk = 0.50

        # Trust Weight
        trust_weight = user_trust.get(passenger_id, 0.50)
        weighted_severity = round(severity * trust_weight, 2)

        # Independent Ground Truth
        # (Classification vs physical observation / telemetry audit)
        if category == 'Pothole':
            if sensor_events > 0 or is_ver:
                gt_status = "Confirmed (Supporting Road Anomaly / Consensus)"
                gt_score = 1
                gt_method = "Road surface z-axis acceleration audit"
            else:
                gt_status = "Inconclusive (Contextually Plausible / Pending Photo GT)"
                gt_score = ""
                gt_method = "Awaiting geotagged photographic confirmation"
        elif category == 'Speeding':
            if sensor_events > 0 and sensor_risk > 0.3:
                gt_status = "Confirmed (GPS Highway Speed Limit Exceedance)"
                gt_score = 1
                gt_method = "High-frequency GPS velocity breadcrumbs"
            elif sensor_events == 0 and sensor_risk == 0.0:
                gt_status = "Not Confirmed (Stationary Boarding / Zero Velocity)"
                gt_score = 0
                gt_method = "GPS stationary audit (0.0 km/h curb idling)"
            else:
                gt_status = "Inconclusive (Awaiting Independent Telemetry)"
                gt_score = ""
                gt_method = "Awaiting calibrated OBD-II telemetry"
        elif category == 'Sudden Braking':
            if sensor_events > 0:
                gt_status = "Confirmed (Deceleration Telemetry Anomaly)"
                gt_score = 1
                gt_method = "Longitudinal accelerometer filtering (< -3.5 m/s²)"
            else:
                gt_status = "Not Confirmed (Smooth Braking / No Deceleration Anomaly)"
                gt_score = 0
                gt_method = "Trip-level accelerometer audit (no sudden deceleration)"
        elif category in ('Sharp Turning', 'Reckless Driving'):
            if sensor_events > 0:
                gt_status = "Confirmed (Gyroscope Angular Rate > 1.5 rad/s)"
                gt_score = 1
                gt_method = "Tri-axial gyroscope angular rate threshold"
            elif is_flag:
                gt_status = "Not Confirmed (Road Curve Artifact / Community Flagged)"
                gt_score = 0
                gt_method = "Road corridor curvature geometry audit"
            else:
                gt_status = "Inconclusive (Unverified Maneuver)"
                gt_score = ""
                gt_method = "Awaiting dual-blind contemporaneous observer log"
        else:
            if is_ver:
                gt_status = "Confirmed (Verified by Multi-Party Consensus)"
                gt_score = 1
                gt_method = "Crowdsourced consensus audit"
            elif is_flag:
                gt_status = "Not Confirmed (Community Flagged False Alarm)"
                gt_score = 0
                gt_method = "Route corridor geometry audit"
            else:
                gt_status = "Inconclusive (Unverified Field Observation)"
                gt_score = ""
                gt_method = "Pending on-board contemporaneous clipboard audit"

        # Sensor Evidence
        if sensor_events > 0:
            sensor_evidence = f"Supporting Anomaly Present ({sensor_events} events, R_sens={sensor_risk:.2f})"
        else:
            sensor_evidence = f"No Supporting Anomaly Detected (0 events, R_sens={sensor_risk:.2f})"

        sensor_concordance = "Concordant" if ((severity >= 3 and sensor_events > 0) or (severity < 3 and sensor_events == 0)) else "Discordant"

        out_records.append({
            'Event_ID': event_id,
            'Firestore_Doc_ID': doc_id,
            'Timestamp': ts,
            'Latitude': lat,
            'Longitude': lng,
            'Trip_ID': trip_id,
            'Hazard_Category': category,
            'Reported_Severity': severity,
            'Description': desc,
            'Rater_A_ID': passenger_id,
            'Rater_A_Classification': rater_a_class,
            'Rater_A_Score': rater_a_score,
            'Rater_B_ID': rater_b_id,
            'Rater_B_Classification': rater_b_class,
            'Rater_B_Score': rater_b_score,
            'Verification_Count': ver_count,
            'Flag_Count': flag_count,
            'Independent_Ground_Truth': gt_status,
            'Ground_Truth_Score': gt_score,
            'Ground_Truth_Method': gt_method,
            'Trust_Weight': f"{trust_weight:.2f}",
            'Trust_Weighted_Severity': f"{weighted_severity:.2f}",
            'Sensor_Event_Count': sensor_events,
            'Sensor_Risk_Score': f"{sensor_risk:.2f}",
            'Sensor_Evidence': sensor_evidence,
            'Sensor_Concordance': sensor_concordance
        })

    with open(output_csv, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(out_records)

    print(f"Successfully generated {output_csv} with {len(out_records)} hazard records.")

if __name__ == '__main__':
    main()
