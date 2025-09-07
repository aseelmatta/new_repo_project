"""
websocket_manager.py
====================

This module starts a simple WebSocket server using the `websockets`
library.  It maintains a set of connected clients and provides a
`broadcast` helper to send JSON messages to all currently connected
clients.  The WebSocket server runs on its own event loop in a
background thread, so it will not block the Flask HTTP server.

Clients can connect to ``ws://<host>:6789/`` (by default) and send
arbitrary text messages.  Incoming messages are currently ignored, but
the server will keep the connection alive so that broadcast messages
can be delivered when server‑side events occur.  To extend the server
for more advanced functionality (e.g. routing messages to specific
clients), you could parse the incoming messages in
``WebSocketManager.handler`` and update internal state accordingly.

Example usage in another module::

    from websocket_manager import manager

    # Send a location update to all connected clients
    manager.broadcast({
        "event": "location_update",
        "courier_id": "abc123",
        "lat": 32.0853,
        "lng": 34.7818,
    })

The WebSocket server will automatically start as soon as this module
is imported.  If you don't want the server to start on import (for
example when running tests), remove the call to ``manager.start()`` at
the bottom of this file and invoke ``manager.start()`` explicitly.

"""

import asyncio
import json
import threading
from typing import Set

import websockets


class WebSocketManager:
    """Manage WebSocket connections and broadcast messages to them.

    The manager maintains a set of active WebSocket connections.  It
    runs a WebSocket server on a background thread with its own event
    loop.  Use :meth:`broadcast` to send a JSON message to all
    connected clients.
    """

    def __init__(self, host: str = "0.0.0.0", port: int = 6789):
        self.host = host
        self.port = port
        # Create a new event loop for the WebSocket server
        self.loop: asyncio.AbstractEventLoop = asyncio.new_event_loop()
        # Keep track of connected WebSocket clients
        self.connected_clients: Set[websockets.WebSocketServerProtocol] = set()

    async def handler(self, websocket: websockets.WebSocketServerProtocol, path: str) -> None:
        """Handle an individual WebSocket connection.

        This adds the connection to the set of active clients and
        removes it when disconnected.  Incoming messages from
        clients are ignored, but you can extend this method to
        implement subscription logic or message routing based on the
        content of the incoming messages.
        """
        # Register client
        self.connected_clients.add(websocket)
        try:
            async for _message in websocket:
                # Currently ignore messages from clients.  In a more
                # sophisticated implementation you might parse JSON
                # messages and use them to manage subscriptions.
                pass
        except websockets.ConnectionClosed:
            # Client disconnected
            pass
        finally:
            # Remove the client from the active set
            self.connected_clients.discard(websocket)

    async def _run_server(self) -> None:
        """Coroutine that runs the WebSocket server forever."""
        async with websockets.serve(self.handler, self.host, self.port):
            # Keep the server running indefinitely
            await asyncio.Future()

    def _start_loop(self) -> None:
        """Start the event loop and run the WebSocket server."""
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self._run_server())

    def start(self) -> None:
        """Start the WebSocket server in a background thread.

        If the server is already running, calling this method again has
        no effect.  The thread is marked as a daemon so it will not
        prevent the application from exiting.
        """
        if hasattr(self, "_thread"):
            # Already started
            return
        self._thread = threading.Thread(target=self._start_loop, daemon=True)
        self._thread.start()
    
    async def send_to(websocket, payload):
        if not isinstance(payload, str):
            payload = json.dumps(payload)
        await websocket.send(payload)
    def broadcast(self, message: dict) -> None:
        """Broadcast a JSON message to all connected clients.

        :param message: A JSON‑serializable dictionary to send to each
            connected WebSocket client.  The message will be encoded
            using :func:`json.dumps`.
        """
        if not self.connected_clients:
            return
        # Serialize the message once to avoid repeated work
        data = json.dumps(message)
        for ws in list(self.connected_clients):
            # Schedule the send coroutine on the server's event loop
            try:
                asyncio.run_coroutine_threadsafe(ws.send(data), self.loop)
            except Exception:
                # If the websocket is closed or the loop is shut down
                # ignore the error.
                pass


# Create a global manager instance and start the server.
manager = WebSocketManager()
try:
    manager.start()
except Exception:
    # If the server fails to start (e.g. port already in use), don't
    # raise; clients won't receive WebSocket updates but the rest of
    # the application will still function.
    pass