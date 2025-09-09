import asyncio
import json
import threading
from typing import Set

import websockets


class WebSocketManager:
    def __init__(self, host: str = "0.0.0.0", port: int = 6789):
        self.host = host
        self.port = port
        # Create a new event loop for the WebSocket server
        self.loop: asyncio.AbstractEventLoop = asyncio.new_event_loop()
        # Keep track of connected WebSocket clients
        self.connected_clients: Set[websockets.WebSocketServerProtocol] = set()
        self.clients_by_user: dict[str, set[websockets.WebSocketServerProtocol]] = {}

    async def handler(self, websocket: websockets.WebSocketServerProtocol) -> None:
        # Register client
        self.connected_clients.add(websocket)
        try:
            async for raw_message in websocket:
                try:
                    data = json.loads(raw_message)
                except Exception:
                    # Skip non‑JSON messages
                    continue
                if isinstance(data, dict):
                    msg_type = data.get("type")
                    if msg_type == "register":
                        uid = data.get("uid")
                        if isinstance(uid, str) and uid:
                            # Add this websocket to the set for the uid
                            self.clients_by_user.setdefault(uid, set()).add(websocket)
                        continue
                continue
        except websockets.ConnectionClosed:
            # Client disconnected
            pass
        finally:
            # Remove the client from the active set
            self.connected_clients.discard(websocket)
            for uid, ws_set in list(self.clients_by_user.items()):
                if websocket in ws_set:
                    ws_set.discard(websocket)
                    if not ws_set:
                        del self.clients_by_user[uid]

    async def _run_server(self) -> None:
        """runs the WebSocket server forever."""
        async with websockets.serve(self.handler, self.host, self.port):
            # Keep the server running indefinitely
            await asyncio.Future()

    def _start_loop(self) -> None:
        """Start the event loop and run the WebSocket server."""
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self._run_server())

    def start(self) -> None:
        if hasattr(self, "_thread"):
            # Already started
            return
        self._thread = threading.Thread(target=self._start_loop, daemon=True)
        self._thread.start()
    
    async def send_to(self,websocket, payload):
        if not isinstance(payload, str):
            payload = json.dumps(payload)
        await websocket.send(payload)
    def broadcast(self, message: dict) -> None:
        if not self.connected_clients:
            return
        data = json.dumps(message)
        for ws in list(self.connected_clients):
            try:
                asyncio.run_coroutine_threadsafe(ws.send(data), self.loop)
            except Exception:
                # ignore broken sockets; they will be removed on disconnect
                pass

    def send_to_user(self, uid: str, message: dict) -> None:
        if not uid:
            return
        ws_set = self.clients_by_user.get(uid)
        if not ws_set:
            return
        data = json.dumps(message)
        for ws in list(ws_set):
            try:
                asyncio.run_coroutine_threadsafe(ws.send(data), self.loop)
            except Exception:
                # ignore broken sockets; cleanup occurs in handler
                pass


# Create a global manager instance and start the server.
manager = WebSocketManager()
