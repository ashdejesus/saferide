# Week 2 — UI Skeleton (M3 Expressive) ✅

## Completed Deliverables

### ✅ Material 3 Expressive Theme
- Implemented `DynamicSchemeVariant.expressive` for vibrant colors
- Stadium-shaped buttons and chips for modern look
- Enhanced border radius (28px) for cards and inputs
- Smooth animations and elevated UI elements
- Color-coded feedback system throughout

### ✅ 1. Home Screen (Dashboard)
**Location:** `lib/screens/dashboard_screen.dart`

**Features:**
- Trip status pill showing tracking state
- Quick sync button with status banner
- Trip start/stop card with current speed
- Live sensor data card (when trip active):
  - Current acceleration
  - Average acceleration
  - Turn rate (color-coded by safety level)
- Unsafe events grid (4 stat cards)
- Recent events timeline
- Trip mini HUD when tracking

### ✅ 2. Trip Start/Stop
**Location:** `lib/widgets/trip_action_sheet.dart`

**Features:**
- Modal bottom sheet with drag handle
- Optional route name input
- Real-time event counters during trip
- Start/Stop button with icons
- Permission handling for location

### ✅ 3. Report Incident
**Location:** `lib/screens/report_screen.dart`

**Features:**
- Category selection using FilterChips (wrapping layout)
- 8 incident categories:
  - Speeding
  - Reckless Overtaking
  - Sudden Braking
  - Sharp Turning
  - Overcrowding
  - Harassment / Security
  - Vehicle Condition
  - Other
- Severity slider (1-5)
- Optional notes field
- Submit button (disabled when no active trip)
- User guidance text

### ✅ 4. Trip Summary (List View)
**Location:** `lib/screens/trips_screen.dart`

**Features:**
- Scrollable list of all trips
- Trip cards showing:
  - Route name or date
  - Risk score
  - Event counts (speeding, braking, turning)
  - Duration
  - Color-coded risk badge (Low/Medium/High)
- Tap to view detailed summary
- Empty state with CTA to start first trip

### ✅ 5. Trip Detail Screen
**Location:** `lib/screens/trip_detail_screen.dart`

**Features:**
- Large risk score header (color-coded)
- Trip information card:
  - Duration
  - Date & time range
  - Sync status
- Safety events breakdown
- Route map with start/end markers
- Share button (placeholder)

### ✅ 6. Ratings (Placeholder)
**Location:** `lib/screens/ratings_screen.dart`

**Features:**
- Three rating categories:
  - Driver (person icon)
  - Vehicle Condition (bus icon)
  - Route & Timing (route icon)
- Interactive sliders with star visualization
- Real-time rating labels (Excellent → Very Poor)
- Optional feedback text field
- Submit button with confirmation
- Info card explaining importance of ratings

### ✅ 7. Map Screen
**Location:** `lib/screens/map_screen.dart`

**Features:**
- Live route visualization using FlutterMap
- Polyline showing traveled path
- Current location marker
- Empty state when no active trip
- Trip mini HUD overlay when tracking

### ✅ 8. Navigation & State
**Location:** `lib/app.dart`

**Features:**
- Bottom NavigationBar with 5 tabs:
  1. Home (Dashboard)
  2. Report (Incident reporting)
  3. Map (Live route)
  4. Trips (Trip history)
  5. Rate (Feedback)
- IndexedStack for screen management
- Material 3 expressive navigation indicators
- Provider state management:
  - TripController (trip state & sensor data)
  - SyncService (Firebase sync)
  - AppDatabase (local storage)

## Additional Features Implemented

### Sensor Data Exposure
- Real-time accelerometer data
- Gyroscope turn rate tracking
- Sliding window averaging
- Visual feedback in UI

### Widgets Library
- `EmptyState` - Placeholder with CTA
- `SectionHeader` - Consistent section titles
- `StatCard` - Metric display cards
- `TripMiniHud` - Compact trip status
- `TripActionSheet` - Bottom sheet for trip controls
- `SensorDataCard` - Live sensor visualization

### State Management
- `TripController` exposes:
  - Trip tracking state
  - Current speed & position
  - Route points
  - Event counts
  - Sensor readings (acceleration, turn rate)
  - Recent events list

## Navigation Flow

```
Home (Dashboard)
├── Start Trip → TripActionSheet
├── View Sensor Data (when tracking)
└── View Recent Events

Report
├── Select Category (FilterChips)
├── Set Severity (Slider)
└── Submit (when trip active)

Map
├── View Live Route
└── See Trip HUD (when tracking)

Trips
├── View Trip List
└── Tap Trip → TripDetailScreen
    ├── View Risk Score
    ├── View Trip Info
    ├── View Safety Events
    └── View Route Map

Rate
├── Rate Driver, Vehicle, Route
├── Add Feedback
└── Submit Ratings
```

## Design System Compliance

### Material 3 Expressive Elements
✅ Stadium-shaped buttons  
✅ Enhanced border radius (28px)  
✅ Vibrant color scheme  
✅ Elevated components  
✅ Smooth transitions  
✅ Color-coded feedback  
✅ Proper spacing (20/24px rhythm)  
✅ Icon-text combinations  
✅ Filled/Outlined button variants  

### Accessibility
✅ Proper contrast ratios  
✅ Touch targets (48px minimum)  
✅ Clear visual hierarchy  
✅ Icon labels  
✅ Color + text indicators  

## Testing Checklist

- [x] All screens render without errors
- [x] Navigation between all 5 tabs works
- [x] Trip start/stop flow functional
- [x] Incident report form validates
- [x] Trip list displays and navigates to detail
- [x] Ratings can be adjusted and submitted
- [x] Map displays when trip active
- [x] Sensor data updates in real-time
- [x] Empty states show appropriate CTAs
- [x] Material 3 Expressive theme applied consistently

## Next Steps (Week 3)

1. Connect Firebase for data sync
2. Implement actual GPS tracking
3. Add real sensor event detection
4. Store ratings in database
5. Add trip filtering/search
6. Implement share functionality
7. Add offline support
8. Performance optimization
