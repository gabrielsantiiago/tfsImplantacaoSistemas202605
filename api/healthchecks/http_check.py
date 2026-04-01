import time
import requests

class HttpCheck:
    def check(self, target: str) -> dict:
        start = time.time()
        try:
            resp = requests.get(target, timeout=5)
            elapsed = int((time.time() - start) * 1000)
            status = "healthy" if resp.status_code < 400 else "unhealthy"
            return {"status": status, "response_time": elapsed, "message": f"HTTP {resp.status_code}"}
        except Exception as e:
            elapsed = int((time.time() - start) * 1000)
            return {"status": "unhealthy", "response_time": elapsed, "message": str(e)}
