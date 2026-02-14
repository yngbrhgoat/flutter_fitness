# Training App with Live Mode

Cross-platform Flutter app for structured workout sessions with exercise browsing, recommendation generation, live guidance, and user history tracking.

## Implemented Features

- Exercise catalog with:
  - name, description, equipment, muscle groups, optional media URL
  - suitability rating (0-10) per goal
  - recommended sets, repetitions, and duration per goal
- Exercise browser with filters:
  - goal suitability
  - muscle group
  - required equipment
- Exercise detail screen with all goal configurations
- Validated form to add new exercises
- Seed catalog includes 15+ exercises across multiple muscle groups
- User management:
  - login/create by username
  - quick login from 3 most recent users
- History screen:
  - per-session details (date, exercises, duration)
  - date range filtering
  - summary stats (total sessions, total exercise time, most frequent exercises, current week exercises)
- Recommendation flow:
  - goal + max duration input
  - ranking by suitability + novelty factor from user history
  - exercise selection and reorder before training
  - estimated total training time with over-budget warning
- Live Mode:
  - sequential exercise execution in chosen order
  - elapsed timers, set and repetition guidance
  - automatic set progression by recommended duration
  - manual next set / next exercise / skip
  - pause/resume and early end
  - configurable rest timer (30/45/60s)
  - transition signal (visual + system alert)
  - pace indicator and overall progress
- Session summary at end:
  - total time
  - completed exercises
  - skipped exercises
  - total completed sets
  - persisted into user history

## Backend + Persistence Architecture

The app uses a backend abstraction (`BackendDataSource`) with two implementations:

- `MockBackendDataSource`
  - in-memory data store
  - default mode for local development/testing
  - allows running the app without a server
- `RestBackendDataSource`
  - placeholder adapter for server API integration
  - intended to connect to a backend service backed by PostgreSQL

### PostgreSQL Schema

Normalized schema is defined in:

- `database/schema.sql`

Tables include:

- `training_goals`
- `users`
- `exercises`
- `muscle_groups`
- `exercise_muscle_groups`
- `exercise_goal_configs`
- `training_sessions`
- `training_session_entries`

The schema enforces:

- suitability rating range 0-10
- required zero-values when suitability is 0
- required positive recommendation values when suitability > 0

## Running the App

### Local mode (no server required)

```bash
flutter run
```

Default behavior uses the in-memory backend so the app starts immediately.

### Server mode (REST + PostgreSQL)

Set `USE_MOCK_BACKEND=false` and provide a backend URL:

```bash
flutter run \
  --dart-define=USE_MOCK_BACKEND=false \
  --dart-define=BACKEND_BASE_URL=https://your-api.example.com
```

Then implement `RestBackendDataSource` methods for your API contract.

## Testing

Business logic tests cover:

- recommendation scoring (suitability + novelty)
- training time estimation and budget checks
- completion percentage
- tempo guidance computation
- history date range filtering
- statistics calculations

Run tests:

```bash
flutter test
```

## Project Structure

- `lib/src/models/domain_models.dart`: domain models and enums
- `lib/src/services/*`: recommendation/planning/metrics/history/statistics logic
- `lib/src/data/*`: repository and backend data source interfaces/implementations
- `lib/src/ui/training_app.dart`: app screens and live mode flow
- `database/schema.sql`: PostgreSQL schema
- `test/services/*`: unit tests for core business logic
