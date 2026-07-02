# Reports collection schema

Path: `reports/{reportId}`

Recommended fields:

- `rating` (int, required): 1..5 safety rating (1 = safest, 5 = most risky)
- `trust` (number, optional): 0.0..1.0 trust/confidence of the reporter (default 1.0)
- `lat` (number, optional): latitude of reported event
- `lng` (number, optional): longitude of reported event
- `tripId` (int, optional): local trip id the report belongs to
- `category` (string, optional): e.g. "pothole", "aggressive driving"
- `reportedBy` (string, optional): uid of reporter (should match authenticated user)
- `createdAt` (timestamp, required): server timestamp (use `FieldValue.serverTimestamp()` from SDK)

Example document:

```
{
  "rating": 4,
  "trust": 0.9,
  "lat": 14.6038,
  "lng": 120.9885,
  "tripId": 123,
  "category": "pothole",
  "reportedBy": "uid_abc123",
  "createdAt": Timestamp.now()
}
```

Notes:
- The Firestore rules in `firestore.rules` validate `rating` and basic numeric types.
- Prefer using server timestamps (`FieldValue.serverTimestamp()`) for `createdAt`.
- The `trust` field can be used by backend functions to adjust reporter weight.
- If `lat`/`lng` are omitted, markers won't be shown on the map.
