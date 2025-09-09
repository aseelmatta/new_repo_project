# ws_probe.py
import asyncio, json, websockets

async def main():
    uri = "ws://127.0.0.1:6789"
    async with websockets.connect(uri) as ws:
        # register as a fake courier
        await ws.send(json.dumps({"type":"register","uid":"probe-courier"}))
        print("registered; waiting for messages…")
        while True:
            print("recv:", await ws.recv())

asyncio.run(main())
