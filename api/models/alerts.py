import os
import requests
import logging

log = logging.getLogger(__name__)
WEBHOOK_URL = os.getenv("WEBHOOK_URL", "")

class AlertsModel:
    def __init__(self, db_url):
        self.db_url = db_url

    def fire(self, conn, service, result):
        cur = conn.cursor()
        severity = "critical" if result["status"] == "unhealthy" else "warning"
        message = f"Service '{service['name']}' is {result['status']}: {result.get('message', '')}"
        cur.execute(
            "INSERT INTO alerts (service_id, rule_name, severity, message) VALUES (%s,%s,%s,%s)",
            (service["id"], "service_down", severity, message),
        )
        conn.commit()
        cur.close()
        self._send_webhook(service["name"], severity, message)

    def _send_webhook(self, service_name, severity, message):
        if not WEBHOOK_URL:
            return
        try:
            requests.post(WEBHOOK_URL, json={
                "service": service_name,
                "severity": severity,
                "message": message,
            }, timeout=5)
        except Exception as e:
            log.warning("Webhook failed: %s", e)

    def list(self, conn, resolved=False):
        cur = conn.cursor()
        cur.execute(
            "SELECT a.*, s.name AS service_name FROM alerts a JOIN services s ON s.id=a.service_id WHERE a.resolved=%s ORDER BY a.created_at DESC",
            (resolved,),
        )
        rows = [dict(r) for r in cur.fetchall()]
        cur.close()
        return rows

    def resolve(self, conn, alert_id):
        cur = conn.cursor()
        cur.execute(
            "UPDATE alerts SET resolved=TRUE, resolved_at=NOW() WHERE id=%s",
            (alert_id,),
        )
        conn.commit()
        cur.close()
