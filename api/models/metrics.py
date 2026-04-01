import psutil

class MetricsModel:
    def __init__(self, db_url):
        self.db_url = db_url

    def collect_system(self, conn, service_id):
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO metrics (service_id, cpu_usage, memory_usage, disk_usage, error_rate) VALUES (%s,%s,%s,%s,%s)",
            (
                service_id,
                psutil.cpu_percent(interval=1),
                psutil.virtual_memory().percent,
                psutil.disk_usage("/").percent,
                0.0,
            ),
        )
        conn.commit()
        cur.close()

    def get_latest(self, conn):
        cur = conn.cursor()
        cur.execute("""
            SELECT DISTINCT ON (service_id) m.*, s.name
            FROM metrics m JOIN services s ON s.id = m.service_id
            ORDER BY service_id, recorded_at DESC
        """)
        rows = [dict(r) for r in cur.fetchall()]
        cur.close()
        return rows

    def get_history(self, conn, service_id, limit=100):
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM metrics WHERE service_id=%s ORDER BY recorded_at DESC LIMIT %s",
            (service_id, limit),
        )
        rows = [dict(r) for r in cur.fetchall()]
        cur.close()
        return rows
