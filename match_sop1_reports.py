import csv
from datetime import datetime, timedelta

# SOP 1 trips with verified ground-truth (from Observation Sheets 1-7, Appendix D)
sop1_trips = [
    {
        'trip_id': 'PL-DZ-01',
        'start': '2026-10-04T13:26:55',
        'end': '2026-10-04T13:31:25',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': False, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': True, 'Hazard': False, 'Accident': False
        },
        'notes': 'Road unevenness/potholes observed. No unsafe driver maneuver.'
    },
    {
        'trip_id': 'DZ-PL-02',
        'start': '2026-10-04T19:20:14',
        'end': '2026-10-04T19:23:55',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': False, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'Road curve at Diezmo exit. No unsafe driver action. FP by sensor.'
    },
    {
        'trip_id': 'BNY-SALA-03',
        'start': '2026-10-05T16:54:43',
        'end': '2026-10-05T17:02:22',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': False, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'Road curves on Manila South Rd. No unsafe driver action.'
    },
    {
        'trip_id': 'SALA-BNY-04',
        'start': '2026-10-05T21:58:31',
        'end': '2026-10-05T22:01:49',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': True, 'Sudden Braking': False,
            'Reckless Driving': True, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'CONFIRMED: sudden overtaking swerve at 22:01:44. Sharp turn + reckless driving confirmed.'
    },
    {
        'trip_id': 'BNY-PNC-05',
        'start': '2026-10-06T12:57:00',
        'end': '2026-10-06T13:02:10',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': False, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'Calm student commute. No unsafe events.'
    },
    {
        'trip_id': 'PNC-BNY-06',
        'start': '2026-10-06T16:32:13',
        'end': '2026-10-06T16:36:02',
        'confirmed': {
            'Speeding': False, 'Sharp Turning': False, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'Smooth return commute. No unsafe events.'
    },
    {
        'trip_id': 'CMC-LB-07',
        'start': '2026-09-18T20:54:42',
        'end': '2026-09-18T21:18:23',
        'confirmed': {
            'Speeding': True, 'Sharp Turning': True, 'Sudden Braking': False,
            'Reckless Driving': False, 'Pothole': False, 'Hazard': False, 'Accident': False
        },
        'notes': 'CONFIRMED: sustained speeding >60km/h + 4 lateral sway events on highway.'
    },
]

# Read passenger_reports.csv
reports = []
with open(r'passenger_reports.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        reports.append(row)

print(f'Total passenger reports in CSV: {len(reports)}')

# Match reports to SOP 1 trips by timestamp
# passenger_reports.timestamp is UTC ('Z' suffix)
# SOP1 trip times are Philippine local time (UTC+8)
# So: ts_ph = ts_utc + 8h

matched = []
for trip in sop1_trips:
    trip_start_ph = datetime.fromisoformat(trip['start'])
    trip_end_ph = datetime.fromisoformat(trip['end'])
    buf = timedelta(minutes=10)

    for r in reports:
        ts_str = r.get('timestamp', '').replace('Z', '').strip()
        if not ts_str:
            continue
        try:
            ts_utc = datetime.fromisoformat(ts_str)
        except Exception:
            continue
        ts_ph = ts_utc + timedelta(hours=8)

        if (trip_start_ph - buf) <= ts_ph <= (trip_end_ph + buf):
            cat = r['category']
            gt_confirms = trip['confirmed'].get(cat, False)
            passenger_reported_incident = True  # They submitted a report = yes
            matched.append({
                'trip_id': trip['trip_id'],
                'report_id': r['id'],
                'category': cat,
                'severity': r['severity'],
                'passenger_id': r['passengerId'][:8],
                'ts_ph': str(ts_ph),
                'is_flagged': r['isFlagged'],
                'passenger_reported': passenger_reported_incident,
                'gt_confirms': gt_confirms,
                'notes': trip['notes'],
            })

print(f'\nMatched reports to SOP1 trips: {len(matched)}')
for m in matched:
    cell = ''
    if m['passenger_reported'] and m['gt_confirms']:
        cell = 'TP'
    elif m['passenger_reported'] and not m['gt_confirms']:
        cell = 'FP'
    elif not m['passenger_reported'] and m['gt_confirms']:
        cell = 'FN'
    else:
        cell = 'TN'
    print(f"  {m['trip_id']:12s} | {m['category']:16s} | sev={m['severity']} | ts={m['ts_ph']} | GT={m['gt_confirms']} | flagged={m['is_flagged']} | {cell}")

# Check if there are reports on SOP1 dates but outside windows
sop1_dates = ['2026-10-04', '2026-10-05', '2026-10-06', '2026-09-18']
unmatched_on_dates = []
for r in reports:
    ts_str = r.get('timestamp', '').replace('Z','').strip()
    if not ts_str:
        continue
    try:
        ts_utc = datetime.fromisoformat(ts_str)
        ts_ph = ts_utc + timedelta(hours=8)
        date_str = ts_ph.strftime('%Y-%m-%d')
        if date_str in sop1_dates:
            # Check if in matched
            already = any(m['report_id'] == r['id'] for m in matched)
            if not already:
                unmatched_on_dates.append((r['id'], r['category'], str(ts_ph), r['passengerId'][:8]))
    except:
        continue

print(f'\nReports on SOP1 dates but OUTSIDE trip windows (no match): {len(unmatched_on_dates)}')
for u in unmatched_on_dates:
    print(f'  {u}')
