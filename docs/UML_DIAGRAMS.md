# SafeRide System UML Diagrams

This document contains accurate UML diagrams based on the actual SafeRide system architecture and components.

## 1. Agile Scrum Development Lifecycle

```mermaid
flowchart TD
    A["Requirements Gathering<br/>Phase 1<br/>- Functional Requirements<br/>- Non-functional Requirements<br/>- System Actors & Scope"] --> B["System Design<br/>Phase 2<br/>- Architecture Design<br/>- Module Structure<br/>- Database Schema"]
    B --> C["Development & Implementation<br/>Phase 3<br/>- Flutter Mobile App<br/>- Node.js Backend<br/>- Firebase Integration<br/>- Algorithm Implementation"]
    C --> D["Testing<br/>Phase 4<br/>- Functional Testing<br/>- Performance Testing<br/>- Reliability Validation"]
    D --> E["Deployment<br/>Phase 5<br/>- Production Release<br/>- Real-time Monitoring<br/>- Configuration Setup"]
    E --> F["Feedback & Evaluation<br/>Phase 6<br/>- User Feedback Collection<br/>- ISO/IEC 25010 Assessment<br/>- Performance Analysis"]
    F -.->|Continuous Improvement| A
    
    style A fill:#e1f5ff
    style B fill:#f3e5f5
    style C fill:#e8f5e9
    style D fill:#fff3e0
    style E fill:#fce4ec
    style F fill:#f1f8e9
```

## 2. System Actors & Use Cases

```mermaid
graph TB
    subgraph SafeRideSystem["SafeRide System"]
        UC1["Start Trip<br/>Monitoring"]
        UC2["View Transportation<br/>Safety Score"]
        UC3["Submit Incident<br/>Report"]
        UC4["Detect Unsafe<br/>Driving Events"]
        UC5["Calculate Risk<br/>Scores"]
        UC6["Evaluate Report<br/>Credibility"]
        UC7["View Trip<br/>History"]
        UC8["Rate Trip<br/>Safety"]
    end
    
    PASSENGER["👤<br/>Passenger"]
    
    PASSENGER -->|initiates| UC1
    PASSENGER -->|views| UC2
    PASSENGER -->|submits| UC3
    PASSENGER -->|rates| UC8
    PASSENGER -->|views| UC7
    
    UC1 -.->|includes| UC4
    UC4 -.->|includes| UC5
    UC3 -.->|includes| UC6
    UC5 -.->|affects| UC2
    UC6 -.->|affects| UC2
    
    style SafeRideSystem fill:#f0f0f0,stroke:#333
    style PASSENGER fill:#bbdefb
    style UC1 fill:#fff9c4
    style UC2 fill:#fff9c4
    style UC3 fill:#fff9c4
    style UC7 fill:#fff9c4
    style UC8 fill:#fff9c4
    style UC4 fill:#f8bbd0
    style UC5 fill:#f8bbd0
    style UC6 fill:#f8bbd0
```

## 3. Component Architecture Diagram

```mermaid
graph TB
    APP["Mobile Application<br/>Flutter"]
    
    SENSOR_MODULE["Sensor Processing Module<br/>- SensorService<br/>- SlidingWindow<br/>- SensorReading"]
    
    DETECT_MODULE["Unsafe Driving Detection<br/>- WindowMetrics<br/>- AdaptiveThresholds<br/>- computeAccelerationMagnitude<br/>- computeGyroMagnitude<br/>- movingAverageFilter<br/>- detectPothole"]
    
    TRUST_MODULE["Trust-Weighted Reporting<br/>- TrustScoringService<br/>- calculateConsistencyScore<br/>- calculateAnomalyScore<br/>- calculateSensorAlignmentScore"]
    
    RISK_ENGINE["Risk Fusion Engine<br/>- RiskWeights<br/>- Risk Score Computation<br/>- Final Safety Score"]
    
    BACKEND["Backend Services<br/>Firebase Cloud Functions"]
    
    DB["Firebase Firestore<br/>Cloud Database"]
    
    REPORT_SERVICE["Passenger Reporting Service<br/>PassengerReport Model"]
    
    APP -->|collects sensors| SENSOR_MODULE
    SENSOR_MODULE -->|processes| DETECT_MODULE
    APP -->|submits| REPORT_SERVICE
    REPORT_SERVICE -->|evaluates trust| TRUST_MODULE
    DETECT_MODULE -->|behavioral risk| RISK_ENGINE
    TRUST_MODULE -->|report risk| RISK_ENGINE
    RISK_ENGINE -->|computes| APP
    APP -->|communicates| BACKEND
    BACKEND -->|stores/retrieves| DB
    
    style APP fill:#c8e6c9
    style SENSOR_MODULE fill:#bbdefb
    style DETECT_MODULE fill:#fff9c4
    style TRUST_MODULE fill:#f8bbd0
    style RISK_ENGINE fill:#ffccbc
    style BACKEND fill:#ffe0b2
    style DB fill:#dcedc8
```

## 4. Class Diagram - Core Models & Services

```mermaid
classDiagram
    class Trip {
        int id
        DateTime startTime
        DateTime endTime
        double startLat
        double startLng
        double endLat
        double endLng
        String routeName
        double riskScore
        int speedingCount
        int brakingCount
        int turningCount
        List routePoints
        SyncStatus syncStatus
        copyWith()
        toMap()
        fromMap()
    }
    
    class PassengerReport {
        int id
        int tripId
        String category
        int severity
        String description
        DateTime createdAt
        SyncStatus syncStatus
        copyWith()
        toMap()
        fromMap()
    }
    
    class PassengerTrustMetrics {
        int id
        String passengerId
        int totalReports
        double consistencyScore
        double anomalyScore
        double sensorAlignmentScore
        double overallTrust
        DateTime lastUpdated
        int verifiedCount
        int flaggedCount
        SyncStatus syncStatus
        copyWith()
        toMap()
        fromMap()
    }
    
    class SensorReading {
        double speed
        double accelX
        double accelY
        double accelZ
        double gyroX
        double gyroY
        double gyroZ
        double altitude
        double distance
        DateTime timestamp
    }
    
    class WindowMetrics {
        double averageSpeed
        double maxAngularVelocity
        List speedVariations
        double maxSpeedDeceleration
        List readings
        bool hasOverspeeding
        bool hasHarshBraking
        bool hasSharpTurning
    }
    
    class AdaptiveThresholds {
        double thetaSpeedingBase
        double thetaBrakingBase
        double thetaTurningBase
        double thetaPothole
        double contextRoad
        double contextVehicle
        double contextTraffic
        getAdaptiveThreshold()
        updateContextFactors()
    }
    
    class RiskWeights {
        double w1
        double w2
        double w3
        double w4
        double w5
        double phi
    }
    
    class SensorService {
        userAccelerometerStream()
        gyroscopeStream()
    }
    
    class SlidingWindow {
        int size
        add()
        average
        max
    }
    
    class TrustScoringService {
        calculateConsistencyScore()
        calculateAnomalyScore()
        calculateSensorAlignmentScore()
    }
    
    Trip "1" --> "*" PassengerReport
    Trip "1" --> "*" SensorReading
    Trip "1" --> "*" WindowMetrics
    PassengerReport --> PassengerTrustMetrics
    WindowMetrics --> AdaptiveThresholds
    WindowMetrics --> RiskWeights
    SensorService --> SensorReading
    SensorService --> SlidingWindow
    PassengerReport --> TrustScoringService
```

## 5. Trip Monitoring Activity Diagram

```mermaid
flowchart TD
    A["Passenger Initiates Trip<br/>via DashboardScreen"] --> B["LocationService Requests<br/>GPS Permission"]
    B --> C["PermissionService Grants<br/>Location Access"]
    C --> D["SensorService Starts<br/>Accelerometer Stream"]
    D --> E["SensorService Starts<br/>Gyroscope Stream"]
    E --> F["SlidingWindow Created<br/>for Data Buffering"]
    F --> G["Trip Record Created<br/>Trip Model Instance"]
    G --> H["Real-time SensorReading<br/>Collection Begins"]
    H --> I["SyncService Queues<br/>Sensor Data"]
    I --> J["Backend Receives<br/>Real-time Stream"]
    J --> K["Trip Monitoring<br/>Active State"]
    
    style A fill:#e3f2fd
    style K fill:#c8e6c9
```

## 6. Incident Report Submission Activity Diagram

```mermaid
flowchart TD
    A["Passenger Submits Report<br/>via ReportScreen"] --> B["PassengerReportingService<br/>Receives Report"]
    B --> C["PassengerReport Model<br/>Created"]
    C --> D["Extract Trip Context<br/>from Trip Model"]
    D --> E["Retrieve PassengerTrustMetrics"]
    E --> F["TrustScoringService<br/>calculateConsistencyScore"]
    F --> G["TrustScoringService<br/>calculateAnomalyScore"]
    G --> H["TrustScoringService<br/>calculateSensorAlignmentScore"]
    H --> I["Compute Overall<br/>Trust Score"]
    I --> J{"Trust Score<br/>Within Bounds?"}
    J -->|Yes| K["Store in Firestore<br/>via FirestoreService"]
    J -->|No| L["Flag for<br/>Manual Review"]
    K --> M["Update PassengerTrustMetrics"]
    L --> M
    M --> N["SyncService Queues<br/>for Backend Sync"]
    N --> O["Report Processing<br/>Complete"]
    
    style A fill:#fff3e0
    style O fill:#c8e6c9
```

## 7. Risk Score Computation Activity Diagram

```mermaid
flowchart TD
    A["Trip Monitoring Complete"] --> B["Retrieve SensorReading<br/>Collection from Trip"]
    B --> C["SlidingWindow Applies<br/>Moving Average Filter"]
    C --> D["Compute WindowMetrics<br/>for Each Window"]
    D --> E["Calculate Acceleration<br/>computeAccelerationMagnitude"]
    E --> F["Calculate Gyro Magnitude<br/>computeGyroMagnitude"]
    F --> G["Apply AdaptiveThresholds<br/>Context Factors"]
    G --> H["Detect Unsafe Events<br/>via AdaptiveThresholds"]
    H --> I["Categorize Events<br/>Overspeeding/Braking/Turning/Pothole"]
    I --> J["Retrieve PassengerReport<br/>for Trip"]
    J --> K["Filter by Trust Score<br/>from PassengerTrustMetrics"]
    K --> L["Compute Behavioral<br/>Risk from WindowMetrics"]
    L --> M["Compute Report<br/>Risk from Reports"]
    M --> N["Apply RiskWeights<br/>w1-w5 & phi"]
    N --> O["Fuse Scores<br/>Weighted Combination"]
    O --> P["Generate Final<br/>Safety Score"]
    P --> Q["Store in Trip Model<br/>Update riskScore"]
    Q --> R["Sync to Firestore<br/>via SyncService"]
    R --> S["Risk Score<br/>Computation Complete"]
    
    style A fill:#f3e5f5
    style S fill:#c8e6c9
```

## 8. Trust Scoring Algorithm Workflow

```mermaid
flowchart TD
    A["PassengerReport Created"] --> B["Extract Report Severity<br/>1-5 Scale"]
    B --> C["Retrieve Historical Reports<br/>from PassengerTrustMetrics"]
    C --> D["Calculate Consistency<br/>calculateConsistencyScore<br/>Based on Variance"]
    D --> E["Calculate Anomaly<br/>calculateAnomalyScore<br/>Z-score Method"]
    E --> F["Detect Sensor Events<br/>from WindowMetrics"]
    F --> G["Calculate Sensor Alignment<br/>calculateSensorAlignmentScore"]
    G --> H["Weighted Combination<br/>of Three Scores"]
    H --> I["Generate Trust Value<br/>0-1 Range"]
    I --> J["Update PassengerTrustMetrics<br/>overallTrust Field"]
    J --> K["Store in Firestore"]
    
    style A fill:#fce4ec
    style K fill:#c8e6c9
```

## 9. Deployment Architecture Diagram

```mermaid
graph TB
    DEVICE["User Device<br/>Smartphone"]
    
    subgraph Mobile["Mobile Layer"]
        APP["Flutter App<br/>Multiple Screens:<br/>DashboardScreen<br/>MapScreen<br/>ReportScreen<br/>TripsScreen<br/>ProfileScreen<br/>RatingsScreen"]
    end
    
    subgraph Processing["Processing Layer"]
        LOC["LocationService"]
        PERM["PermissionService"]
        SENSOR["SensorService"]
    end
    
    subgraph LocalStorage["Local Storage"]
        DB_LOCAL["SQLite<br/>Trip, Report<br/>PassengerTrustMetrics"]
    end
    
    subgraph Backend["Backend Infrastructure"]
        API["Firebase Cloud Functions"]
        PROCESS["Risk Calculation<br/>& Analysis"]
    end
    
    subgraph Cloud["Cloud Storage"]
        FIRESTORE["Firebase Firestore<br/>- Trip Records<br/>- Incident Reports<br/>- Trust Metrics<br/>- Safety Scores"]
    end
    
    DEVICE --> Mobile
    Mobile --> Processing
    Processing --> LocalStorage
    LocalStorage -.->|SyncService| Backend
    Backend --> Cloud
    Cloud -->|Real-time Updates| Mobile
    
    style DEVICE fill:#bbdefb
    style Mobile fill:#c8e6c9
    style Processing fill:#fff9c4
    style LocalStorage fill:#f8bbd0
    style Backend fill:#ffe0b2
    style Cloud fill:#ffccbc
```

## 10. System Services & Data Flow

```mermaid
graph TB
    APP["Flutter Application"]
    
    AUTH["AuthService<br/>User Authentication"]
    PREF["PreferencesService<br/>Local Settings"]
    LOC["LocationService<br/>GPS Coordinates"]
    PERM["PermissionService<br/>App Permissions"]
    SENSOR["SensorService<br/>Accelerometer/Gyroscope"]
    
    REPORT["PassengerReportingService<br/>Submit & Manage Reports"]
    TRUST["TrustScoringService<br/>Compute Trust Metrics"]
    RISK["RiskScoringService<br/>Calculate Safety Scores"]
    
    SYNC["SyncService<br/>Backend Synchronization"]
    NOTIFY["NotificationService<br/>User Alerts"]
    
    FIRESTORE["FirestoreService<br/>Database Operations"]
    
    APP --> AUTH
    APP --> PREF
    APP --> LOC
    APP --> PERM
    APP --> SENSOR
    
    APP --> REPORT
    REPORT --> TRUST
    TRUST --> RISK
    
    SENSOR --> RISK
    RISK --> SYNC
    REPORT --> SYNC
    TRUST --> SYNC
    
    SYNC --> FIRESTORE
    SYNC --> NOTIFY
    
    style APP fill:#c8e6c9
    style AUTH fill:#bbdefb
    style PREF fill:#bbdefb
    style LOC fill:#bbdefb
    style PERM fill:#bbdefb
    style SENSOR fill:#bbdefb
    style REPORT fill:#fff9c4
    style TRUST fill:#f8bbd0
    style RISK fill:#ffccbc
    style SYNC fill:#ffe0b2
    style NOTIFY fill:#ffe0b2
    style FIRESTORE fill:#dcedc8
```

## 11. Feedback & Evaluation Cycle

```mermaid
flowchart TD
    A["Deploy SafeRide<br/>to Production"] --> B["Collect User Feedback<br/>via RatingsScreen & Analytics"]
    B --> C["Gather IT Expert Evaluations<br/>ISO/IEC 25010:2023"]
    C --> D["Analyze Quality Metrics<br/>- Functional Suitability<br/>- Reliability<br/>- Performance Efficiency<br/>- Interaction Capability"]
    D --> E{"Issues or<br/>Improvements<br/>Needed?"}
    E -->|Yes| F["Prioritize Changes<br/>- Algorithm Tuning<br/>- Threshold Recalibration<br/>- UI Refinement<br/>- Performance Optimization"]
    E -->|No| G["System Stable"]
    F --> H["Update AdaptiveThresholds<br/>or RiskWeights"]
    H --> I["Refine TrustScoringService"]
    I --> J["Redeploy Updated<br/>SafeRide Version"]
    J --> K["Monitor Performance<br/>New Metrics"]
    K --> L["Feedback Loop<br/>Continues"]
    L -.->|Return| B
    
    style A fill:#e1f5fe
    style F fill:#fff9c4
    style G fill:#c8e6c9
    style L fill:#ffccbc
```

## 12. Data Model Relationships

```mermaid
erDiagram
    PASSENGER ||--o{ TRIP : "records"
    TRIP ||--o{ SENSOR_READING : "contains"
    TRIP ||--o{ PASSENGER_REPORT : "has"
    PASSENGER ||--|| PASSENGER_TRUST_METRICS : "maintains"
    PASSENGER_REPORT ||--|| PASSENGER_TRUST_METRICS : "influences"
    SENSOR_READING ||--o{ WINDOW_METRICS : "computed-from"
    WINDOW_METRICS ||--|| ADAPTIVE_THRESHOLDS : "uses"
    TRIP ||--|| RISK_SCORE : "generates"
    RISK_SCORE ||--|| RISK_WEIGHTS : "uses"
    
    PASSENGER {
        string id
        string name
        string email
        string phone
    }
    
    TRIP {
        int id
        string passenger_id
        datetime start_time
        datetime end_time
        double start_lat
        double start_lng
        double end_lat
        double end_lng
        double risk_score
        int speeding_count
        int braking_count
        int turning_count
    }
    
    SENSOR_READING {
        int id
        int trip_id
        double speed
        double accel_x
        double accel_y
        double accel_z
        double gyro_x
        double gyro_y
        double gyro_z
        datetime timestamp
    }
    
    PASSENGER_REPORT {
        int id
        int trip_id
        string category
        int severity
        string description
        datetime created_at
    }
    
    PASSENGER_TRUST_METRICS {
        int id
        string passenger_id
        double consistency_score
        double anomaly_score
        double sensor_alignment_score
        double overall_trust
        int verified_count
        int flagged_count
    }
    
    WINDOW_METRICS {
        double avg_speed
        double max_angular_velocity
        bool has_overspeeding
        bool has_harsh_braking
        bool has_sharp_turning
    }
    
    ADAPTIVE_THRESHOLDS {
        double theta_speeding_base
        double theta_braking_base
        double theta_turning_base
        double context_road
        double context_vehicle
        double context_traffic
    }
    
    RISK_SCORE {
        double behavioral_risk
        double report_risk
        double final_score
    }
    
    RISK_WEIGHTS {
        double w1_overspeeding
        double w2_braking
        double w3_turning
        double w4_pothole
        double w5_slope
        double phi_inconsistency
    }
```

---

## Component Summary

### Core Models
- **Trip**: Represents a transportation journey with sensor data
- **PassengerReport**: Incident report submitted by passenger
- **PassengerTrustMetrics**: Trust assessment of passenger's reports
- **SensorReading**: Individual sensor measurement at timestamp
- **WindowMetrics**: Aggregated metrics for sliding window
- **AdaptiveThresholds**: Dynamic detection thresholds
- **RiskWeights**: Weighted coefficients for risk computation

### Core Services
- **SensorService**: Collects accelerometer and gyroscope data
- **SlidingWindow**: Buffers and processes sensor streams
- **TrustScoringService**: Evaluates report credibility
- **RiskScoringService**: Computes transportation safety scores
- **LocationService**: GPS data collection
- **FirestoreService**: Database operations
- **SyncService**: Backend synchronization
- **PassengerReportingService**: Report management

### UI Screens
- AuthScreen, DashboardScreen, MapScreen, ProfileScreen
- RatingsScreen, ReportScreen, SettingsScreen, TripsScreen, TripDetailScreen

