-- Cleaning up existing data in the patient_pii schema
TRUNCATE TABLE patient_pii.patients CASCADE;

-- Inserting synthetic data
INSERT INTO patient_pii.patients (id, first_name, last_name, date_of_birth, gender)
VALUES
    (gen_random_uuid(), 'Synthetic-User-1', 'Alpha', '1985-05-20', 'M'),
    (gen_random_uuid(), 'Synthetic-User-2', 'Beta', '1990-11-12', 'F');

-- Registering an event in audit
INSERT INTO audit.access_logs (event_type, user_id, timestamp)
VALUES ('DB_SEEDING', 'system_initializer', NOW());
