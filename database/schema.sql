-- PostgreSQL schema for Training App with Live Mode
-- Normalized structure for exercises, goals, users, sessions, and session details.

CREATE TABLE IF NOT EXISTS training_goals (
  id SMALLSERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO training_goals (code, name)
VALUES
  ('muscle_gain', 'Muscle Gain'),
  ('weight_loss', 'Weight Loss'),
  ('strength_increase', 'Strength Increase'),
  ('endurance_increase', 'Endurance Increase')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  primary_goal_id SMALLINT NOT NULL REFERENCES training_goals(id) ON DELETE RESTRICT DEFAULT 1,
  last_login_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercises (
  id BIGSERIAL PRIMARY KEY,
  external_key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  media_url TEXT,
  equipment TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS muscle_groups (
  id SMALLSERIAL PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL UNIQUE
);

INSERT INTO muscle_groups (code, name)
VALUES
  ('chest', 'Chest'),
  ('back', 'Back'),
  ('legs', 'Legs'),
  ('core', 'Core'),
  ('arms', 'Arms'),
  ('shoulders', 'Shoulders'),
  ('glutes', 'Glutes'),
  ('full_body', 'Full Body')
ON CONFLICT (code) DO NOTHING;

CREATE TABLE IF NOT EXISTS exercise_muscle_groups (
  exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  muscle_group_id SMALLINT NOT NULL REFERENCES muscle_groups(id) ON DELETE RESTRICT,
  PRIMARY KEY (exercise_id, muscle_group_id)
);

CREATE TABLE IF NOT EXISTS exercise_goal_configs (
  exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  goal_id SMALLINT NOT NULL REFERENCES training_goals(id) ON DELETE RESTRICT,
  suitability_rating SMALLINT NOT NULL CHECK (suitability_rating BETWEEN 0 AND 10),
  recommended_sets INTEGER NOT NULL CHECK (recommended_sets >= 0),
  recommended_repetitions INTEGER NOT NULL CHECK (recommended_repetitions >= 0),
  recommended_duration_seconds INTEGER NOT NULL CHECK (recommended_duration_seconds >= 0),
  PRIMARY KEY (exercise_id, goal_id),
  CONSTRAINT exercise_goal_zero_rule CHECK (
    (suitability_rating = 0 AND recommended_sets = 0 AND recommended_repetitions = 0 AND recommended_duration_seconds = 0)
    OR
    (suitability_rating > 0 AND recommended_sets > 0 AND recommended_repetitions > 0 AND recommended_duration_seconds > 0)
  )
);

CREATE OR REPLACE FUNCTION enforce_single_goal_per_exercise()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  affected_exercise_id BIGINT := COALESCE(NEW.exercise_id, OLD.exercise_id);
  total_count INTEGER;
  suitable_count INTEGER;
BEGIN
  SELECT
    COUNT(*),
    COUNT(*) FILTER (WHERE suitability_rating > 0)
  INTO total_count, suitable_count
  FROM exercise_goal_configs
  WHERE exercise_id = affected_exercise_id;

  IF total_count = 0 THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  IF suitable_count <> 1 THEN
    RAISE EXCEPTION
      'Exercise % must have exactly one suitable goal configuration, found %.',
      affected_exercise_id,
      suitable_count;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_exercise_single_goal ON exercise_goal_configs;
CREATE CONSTRAINT TRIGGER trg_exercise_single_goal
AFTER INSERT OR UPDATE OR DELETE ON exercise_goal_configs
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION enforce_single_goal_per_exercise();

CREATE TABLE IF NOT EXISTS training_sessions (
  id BIGSERIAL PRIMARY KEY,
  external_key TEXT NOT NULL UNIQUE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id SMALLINT NOT NULL REFERENCES training_goals(id) ON DELETE RESTRICT,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  total_duration_seconds INTEGER GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (ended_at - started_at))::INTEGER) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS training_session_entries (
  session_id BIGINT NOT NULL REFERENCES training_sessions(id) ON DELETE CASCADE,
  sequence_index INTEGER NOT NULL CHECK (sequence_index >= 0),
  exercise_id BIGINT NOT NULL REFERENCES exercises(id) ON DELETE RESTRICT,
  completed_sets INTEGER NOT NULL CHECK (completed_sets >= 0),
  planned_sets INTEGER NOT NULL CHECK (planned_sets >= 0),
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds >= 0),
  skipped BOOLEAN NOT NULL,
  PRIMARY KEY (session_id, sequence_index)
);

CREATE INDEX IF NOT EXISTS idx_training_sessions_user_started
  ON training_sessions (user_id, started_at DESC);

CREATE INDEX IF NOT EXISTS idx_training_session_entries_exercise
  ON training_session_entries (exercise_id);
