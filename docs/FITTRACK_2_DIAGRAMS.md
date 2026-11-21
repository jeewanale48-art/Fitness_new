# FitTrack 2.0 – System Diagrams

## 1. System architecture

```mermaid
flowchart TB
    Member[Member Browser] --> Public[Public Website / User Portal]
    Admin[Administrator Browser] --> AdminPortal[Admin Portal]
    Public --> PHP[PHP Application Layer]
    AdminPortal --> PHP
    PHP --> Auth[Session and Role Authorization]
    PHP --> Plans[Diet and Workout Plan Services]
    PHP --> Membership[Manual Subscription Requests]
    PHP --> Coaching[Coach Directory and Booking]
    PHP --> Notify[Notifications and SMTP Mailer]
    Auth --> DB[(MySQL Database)]
    Plans --> DB
    Membership --> DB
    Coaching --> DB
    Notify --> DB
    Notify --> SMTP[Gmail SMTP / PHPMailer]
    Membership --> Proofs[Private Payment Proof Storage]
```

## 2. Registration and personalized content flow

```mermaid
flowchart TD
    A[Open public homepage] --> B[Register account]
    B --> C[Enter profile and preferences]
    C --> D[Choose Beginner / Intermediate / Expert]
    D --> E[Save member profile]
    E --> F[Sign in]
    F --> G[Check active membership]
    G --> H[Match published plans to fitness level]
    H --> I{Premium active?}
    I -->|No| J[Show matching free plans]
    I -->|Yes| K[Show matching free and premium plans]
    J --> L[Show admin assignments and suggestions]
    K --> L
    L --> M[Member dashboard]
```

## 3. Manual subscription workflow

```mermaid
flowchart TD
    A[Member selects duration] --> B[Transfer payment using configured instructions]
    B --> C[Upload payment proof]
    C --> D[Create subscription request]
    D --> E[Admin notification]
    E --> F[Admin reviews proof]
    F --> G{Decision}
    G -->|Approve| H[Set start and expiry dates]
    H --> I[Activate premium access]
    I --> J[In-app notification and SMTP email]
    G -->|Reject| K[Save admin reason]
    K --> L[In-app notification and SMTP email]
```

## 4. Coaching workflow

```mermaid
flowchart TD
    A[Admin creates coach profile] --> B[Admin adds weekly availability]
    B --> C[Coach appears in member portal]
    C --> D[Member chooses coach and date/time]
    D --> E[Check availability and booking conflict]
    E --> F[Save pending booking]
    F --> G[Admin notification]
    G --> H{Admin decision}
    H -->|Approve| I[Confirm booking]
    H -->|Reject| J[Reject booking with note]
    I --> K[Notify member in app and by email]
    J --> K
```

## 5. Role and content access rules

| Area | Member | Administrator |
|---|---|---|
| Public homepage | View | View |
| Personal profile and logs | Own records | View member records |
| Diet/workout content | Matching level and membership | Create and publish |
| Premium content | Active Premium only | Manage content |
| Subscription request | Submit proof and view own status | Review and decide |
| Coach directory | View and request | Create and deactivate |
| Coach bookings | View own requests | Review all requests |
| Suggestions | View own suggestions | Create for members |
| Admin dashboard | No access | Full admin access |

## 6. Main database relationships

```mermaid
erDiagram
    USERS ||--o{ SUBSCRIPTION_REQUESTS : submits
    USERS ||--o{ NOTIFICATIONS : receives
    USERS ||--o{ ADMIN_SUGGESTIONS : receives
    USERS ||--o{ USER_PLAN_ASSIGNMENTS : receives
    USERS ||--o{ COACH_BOOKINGS : requests
    DIET_PLANS ||--o{ USER_PLAN_ASSIGNMENTS : assigned
    WORKOUT_TEMPLATES ||--o{ USER_PLAN_ASSIGNMENTS : assigned
    COACHES ||--o{ COACH_AVAILABILITY : has
    COACHES ||--o{ COACH_BOOKINGS : receives
```

The additive migration is in `database/fittrack_2_migration.sql`. Back up the existing database before importing it.
