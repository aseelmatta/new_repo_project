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
        # Map of user ids to the set of WebSocket connections registered for that user
        # When a client connects they should send a JSON message like
        # {"type": "register", "uid": "someUserId"}.  The handler will
        # add the WebSocket to this mapping so targeted messages can be
        # delivered to a specific courier without broadcasting to everyone.
        self.clients_by_user: dict[str, set[websockets.WebSocketServerProtocol]] = {}

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
            async for raw_message in websocket:
                """
                Listen for incoming messages from the client.  We expect
                clients to send an initial JSON payload of the form
                {"type": "register", "uid": "<userId>"} so that we can
                associate this WebSocket connection with a specific
                authenticated user.  Additional message types can be
                handled here in the future (e.g. unsubscribe, ping/pong).
                Any malformed JSON messages are ignored.
                """
                try:
                    data = json.loads(raw_message)
                except Exception:
                    # Skip non‑JSON messages
                    continue
                if isinstance(data, dict):
                    msg_type = data.get("type")
                    # Handle registration from clients.  The client
                    # should send {"type": "register", "uid": "<uid>"}
                    # immediately after connecting.  We store the
                    # mapping from uid -> WebSocket so that we can
                    # broadcast targeted events later (for example, when a
                    # delivery is assigned to a specific courier).
                    if msg_type == "register":
                        uid = data.get("uid")
                        if isinstance(uid, str) and uid:
                            # Add this websocket to the set for the uid
                            self.clients_by_user.setdefault(uid, set()).add(websocket)
                        continue
                    # Additional message types could be handled here if
                    # necessary (e.g. unsubscribe).
                # If the message is not recognised we ignore it.
                continue
        except websockets.ConnectionClosed:
            # Client disconnected
            pass
        finally:
            # Remove the client from the active set
            self.connected_clients.discard(websocket)
            # Remove the websocket from any user mapping
            # We iterate over a copy of the items because we may mutate
            # the dict during iteration.
            for uid, ws_set in list(self.clients_by_user.items()):
                if websocket in ws_set:
                    ws_set.discard(websocket)
                    if not ws_set:
                        # Remove the key entirely if no more connections
                        del self.clients_by_user[uid]

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
        """
        Broadcast a JSON message to all connected clients.

        This method serializes the given dictionary to a JSON string
        once and sends it to every WebSocket in ``self.connected_clients``.
        If a send fails because the socket is closed, the exception is
        swallowed; the socket will be cleaned up on the next read or
        when it disconnects.
        """
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
        """
        Send a JSON message to all WebSocket connections associated with a
        specific user.  If the user has multiple devices connected,
        each active connection will receive the message.

        :param uid: The user identifier (courier ID) to which the
            message should be delivered.
        :param message: A JSON‑serializable dictionary representing the
            payload to send.
        """
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
try:
    manager.start()
except Exception:
    # If the server fails to start (e.g. port already in use), don't
    # raise; clients won't receive WebSocket updates but the rest of
    # the application will still function.
    pass