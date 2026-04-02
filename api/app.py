import os
import asyncio
import logging
from datetime import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from apscheduler.schedulers.background import BackgroundScheduler
import psycopg2
from psycopg2.extras import RealDictCursor

from models.metrics import MetricsModel
from models.alerts import AlertsModel
from healthchecks.http_check import HttpCheck
from healthchecks.db_check import DbCheck
from healthchecks.custom_check import TcpCheck

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

DB_URL = os.getenv("DATABASE_URL", "postgresql://monitor:monitor@db:5432/monitoring")

def get_db():
    return psycopg2.connect(DB_URL, cursor_factory=RealDictCursor)

metrics_model = MetricsModel(DB_URL)
alerts_model = AlertsModel(DB_URL)

CHECKERS = {
    "http": HttpCheck(),
    "db": DbCheck(),
    "tcp": TcpCheck(),
}

def run_checks():
    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("SELECT * FROM services")
        services = cur.fetchall()
        for svc in services:
            checker = CHECKERS.get(svc["type"])
            if not checker:
                continue
            result = checker.check(svc["target"])
            cur.execute(
                "INSERT INTO health_checks (service_id, status, response_time, message) VALUES (%s, %s, %s, %s)",
                (svc["id"], result["status"], result.get("response_time"), result.get("message")),
            )
            cur.execute(
                "UPDATE services SET last_status=%s, updated_at=NOW() WHERE id=%s",
                (result["status"], svc["id"]),
            )
            if result["status"] == "unhealthy":
                alerts_model.fire(conn, svc, result)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        log.error("run_checks error: %s", e)

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()})

@app.route("/health/status")
def health_status():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT name, last_status, updated_at FROM services ORDER BY name")
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify({"status": "healthy", "services": [dict(r) for r in rows]})

@app.route("/metrics/uptime")
def metrics_uptime():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT s.name,
               ROUND(100.0 * SUM(CASE WHEN h.status='healthy' THEN 1 ELSE 0 END) / COUNT(*), 2) AS uptime_pct
        FROM services s
        JOIN health_checks h ON h.service_id = s.id
        WHERE h.checked_at > NOW() - INTERVAL '24 hours'
        GROUP BY s.name
    """)
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([dict(r) for r in rows])

@app.route("/api/services")
def services():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM services ORDER BY name")
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([dict(r) for r in rows])

@app.route("/api/services/<int:service_id>/history")
def service_history(service_id):
    limit = request.args.get("limit", 50, type=int)
    conn = get_db()
    cur = conn.cursor()
    cur.execute(
        "SELECT * FROM health_checks WHERE service_id=%s ORDER BY checked_at DESC LIMIT %s",
        (service_id, limit),
    )
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([dict(r) for r in rows])

@app.route("/metrics")
@app.route("/api/metrics")
def metrics():
    conn = get_db()
    rows = metrics_model.get_latest(conn)
    conn.close()
    return jsonify(rows)

@app.route("/alerts")
@app.route("/api/alerts")
def alerts():
    resolved = request.args.get("resolved", "false").lower() == "true"
    conn = get_db()
    rows = alerts_model.list(conn, resolved=resolved)
    conn.close()
    return jsonify(rows)

@app.route("/api/alerts/<int:alert_id>/resolve", methods=["POST"])
def resolve_alert(alert_id):
    conn = get_db()
    alerts_model.resolve(conn, alert_id)
    conn.close()
    return jsonify({"ok": True})

@app.route("/api/stats")
def stats():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) AS total FROM services")
    total = cur.fetchone()["total"]
    cur.execute("SELECT COUNT(*) AS healthy FROM services WHERE last_status='healthy'")
    healthy = cur.fetchone()["healthy"]
    cur.execute("SELECT COUNT(*) AS open FROM alerts WHERE resolved=FALSE")
    open_alerts = cur.fetchone()["open"]
    cur.execute("SELECT AVG(response_time) AS avg_rt FROM health_checks WHERE checked_at > NOW() - INTERVAL '1 hour'")
    avg_rt = cur.fetchone()["avg_rt"]
    cur.close(); conn.close()
    return jsonify({
        "total_services": total,
        "healthy_services": healthy,
        "unhealthy_services": total - healthy,
        "open_alerts": open_alerts,
        "avg_response_time_ms": round(float(avg_rt or 0), 2),
    })

if __name__ == "__main__":
    scheduler = BackgroundScheduler()
    scheduler.add_job(run_checks, "interval", seconds=30)
    scheduler.start()
    log.info("Scheduler started — checks every 30s")
    app.run(host="0.0.0.0", port=5000)
