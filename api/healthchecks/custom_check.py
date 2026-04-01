import time
import socket

class TcpCheck:
    def check(self, target: str) -> dict:
        """target format: host:port"""
        start = time.time()
        try:
            host, port = target.rsplit(":", 1)
            with socket.create_connection((host, int(port)), timeout=3):
                pass
            elapsed = int((time.time() - start) * 1000)
            return {"status": "healthy", "response_time": elapsed, "message": "TCP connection OK"}
        except Exception as e:
            elapsed = int((time.time() - start) * 1000)
            return {"status": "unhealthy", "response_time": elapsed, "message": str(e)}


class CustomCheck:
    """Extensible base for custom checks."""
    def check(self, target: str) -> dict:
        raise NotImplementedError
