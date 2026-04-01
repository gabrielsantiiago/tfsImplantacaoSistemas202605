import time
import os
import psycopg2

DB_URL = os.getenv("DATABASE_URL", "postgresql://monitor:monitor@db:5432/monitoring")

class DbCheck:
    def check(self, target: str) -> dict:
        start = time.time()
        try:
            conn = psycopg2.connect(DB_URL)
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
            conn.close()
            elapsed = int((time.time() - start) * 1000)
            return {"status": "healthy", "response_time": elapsed, "message": "DB query OK"}
        except Exception as e:
            elapsed = int((time.time() - start) * 1000)
            return {"status": "unhealthy", "response_time": elapsed, "message": str(e)}
