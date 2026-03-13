-- =============================================================
-- АИС «МедКабинет+» — Схема базы данных для PostgreSQL
-- (первичные ключи: INTEGER GENERATED ALWAYS AS IDENTITY)
-- =============================================================

-- =============================================================
-- 1. СПРАВОЧНИК СТАТУСОВ ЗАПИСИ (AppointmentStatuses)
-- =============================================================
CREATE TABLE IF NOT EXISTS AppointmentStatuses (
    StatusCode   VARCHAR(20)  PRIMARY KEY,
    Description  VARCHAR(100) NOT NULL
);

INSERT INTO AppointmentStatuses (StatusCode, Description) VALUES
    ('scheduled',  'Запланирован'),
    ('completed',  'Проведён'),
    ('cancelled',  'Отменён')
ON CONFLICT (StatusCode) DO NOTHING;


-- =============================================================
-- 2. ПАЦИЕНТЫ (Patients)
-- =============================================================
CREATE TABLE IF NOT EXISTS Patients (
    PatientId        INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LastName         VARCHAR(100) NOT NULL,
    FirstName        VARCHAR(100) NOT NULL,
    MiddleName       VARCHAR(100),
    BirthDate        DATE         NOT NULL,
    Phone            VARCHAR(20)  NOT NULL,
    Email            VARCHAR(100),
    PolicyNumber     VARCHAR(30)  UNIQUE,
    RegistrationDate DATE         NOT NULL DEFAULT CURRENT_DATE,
    CreatedAt        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UpdatedAt        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patients_lastname
    ON Patients (LastName);


-- =============================================================
-- 3. ВРАЧИ (Doctors)
-- =============================================================
CREATE TABLE IF NOT EXISTS Doctors (
    DoctorId       INTEGER      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    LastName       VARCHAR(100) NOT NULL,
    FirstName      VARCHAR(100) NOT NULL,
    MiddleName     VARCHAR(100),
    Specialization VARCHAR(100) NOT NULL,
    Phone          VARCHAR(20),
    IsActive       BOOLEAN      NOT NULL DEFAULT TRUE,
    CreatedAt      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);


-- =============================================================
-- 4. РАСПИСАНИЕ ВРАЧЕЙ (DoctorSchedule)
-- =============================================================
CREATE TYPE schedule_type_enum AS ENUM ('weekly', 'override');

CREATE TABLE IF NOT EXISTS DoctorSchedule (
    ScheduleId    INTEGER            GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    DoctorId      INTEGER            NOT NULL
                      REFERENCES Doctors (DoctorId) ON DELETE CASCADE,
    ScheduleType  schedule_type_enum NOT NULL,
    DayOfWeek     SMALLINT           CHECK (DayOfWeek BETWEEN 0 AND 6),
    SpecificDate  DATE,
    IsWorkingDay  BOOLEAN            NOT NULL DEFAULT TRUE,
    WorkStartTime TIME,
    WorkEndTime   TIME,
    BreakStart    TIME,
    BreakEnd      TIME,

    UNIQUE (DoctorId, ScheduleType, DayOfWeek),
    UNIQUE (DoctorId, SpecificDate)
);

CREATE INDEX IF NOT EXISTS idx_schedule_doctor
    ON DoctorSchedule (DoctorId);


-- =============================================================
-- 5. ЗАПИСИ НА ПРИЁМ (Appointments)
-- =============================================================
CREATE TABLE IF NOT EXISTS Appointments (
    AppointmentId       INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PatientId           INTEGER     NOT NULL
                            REFERENCES Patients (PatientId),
    DoctorId            INTEGER     NOT NULL
                            REFERENCES Doctors (DoctorId),
    AppointmentDateTime TIMESTAMPTZ NOT NULL,
    DurationMinutes     SMALLINT    NOT NULL DEFAULT 30
                            CHECK (DurationMinutes > 0),
    StatusCode          VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                            REFERENCES AppointmentStatuses (StatusCode),
    Comment             TEXT,
    CreatedAt           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UpdatedAt           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (DoctorId, AppointmentDateTime)
);

CREATE INDEX IF NOT EXISTS idx_appointments_patient
    ON Appointments (PatientId);

CREATE INDEX IF NOT EXISTS idx_appointments_doctor_date
    ON Appointments (DoctorId, AppointmentDateTime);

CREATE INDEX IF NOT EXISTS idx_appointments_status
    ON Appointments (StatusCode);


-- =============================================================
-- 6. ИСТОРИЯ ИЗМЕНЕНИЙ ЗАПИСЕЙ (AppointmentsHistory)
-- =============================================================
CREATE TYPE history_change_type_enum AS ENUM ('UPDATE', 'DELETE');

CREATE TABLE IF NOT EXISTS AppointmentsHistory (
    HistoryId           INTEGER                  GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    AppointmentId       INTEGER                  NOT NULL,
    PatientId           INTEGER                  NOT NULL,
    DoctorId            INTEGER                  NOT NULL,
    AppointmentDateTime TIMESTAMPTZ              NOT NULL,
    DurationMinutes     SMALLINT                 NOT NULL,
    StatusCode          VARCHAR(20)              NOT NULL,
    Comment             TEXT,
    ChangedAt           TIMESTAMPTZ              NOT NULL DEFAULT NOW(),
    ChangeType          history_change_type_enum NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_history_appointment
    ON AppointmentsHistory (AppointmentId);
