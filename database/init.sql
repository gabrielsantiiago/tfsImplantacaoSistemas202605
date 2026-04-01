CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL,
    target VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS health_checks (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES services(id),
    status VARCHAR(20) NOT NULL,
    response_time INTEGER,
    message TEXT,
    checked_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES services(id),
    rule_name VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    message TEXT,
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS metrics (
    id SERIAL PRIMARY KEY,
    service_id INTEGER REFERENCES services(id),
    cpu_usage FLOAT,
    memory_usage FLOAT,
    disk_usage FLOAT,
    error_rate FLOAT,
    recorded_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_health_checks_service_time ON health_checks(service_id, checked_at DESC);
CREATE INDEX idx_alerts_service_resolved ON alerts(service_id, resolved);
CREATE INDEX idx_metrics_service_time ON metrics(service_id, recorded_at DESC);

INSERT INTO services (name, type, target) VALUES
    ('api', 'http', 'http://api:5000/health'),
    ('database', 'db', 'db:5432'),
    ('dashboard', 'http', 'http://dashboard:80'),
    ('redis', 'tcp', 'redis:6379')
ON CONFLICT (name) DO NOTHING;
