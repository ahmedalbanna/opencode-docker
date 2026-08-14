# Docker Network Reset — new gateway IP every cycle

## Problem
Docker's default bridge reuses the same subnet (e.g. `172.21.0.0/16`) for a
network recreated under the same name, so the container IP (172.21.0.2) and
gateway (172.21.0.1) stayed identical across `docker compose down && up`.

To get a **new gateway IP on every restart**, the network must be recreated
with a NEW subnet each time.

## Solution
Two wrapper scripts replace the raw `docker compose down` / `docker compose up`:

| Command | What it does |
|---------|--------------|
| `./opencode-down.sh` | Stops opencode and removes the `opencode-net` network |
| `./opencode-up.sh`   | Picks a random `/16` subnet, creates `opencode-net` with that subnet/gateway, starts opencode, prints the new IP + gateway + UUID |

`docker-compose.yml` now uses an **external** network named `opencode-net`
(created by `opencode-up.sh`), so the gateway is different on every cycle.

## Usage (the new way)
```bash
cd /home/frappe/opencode-docker
./opencode-up.sh      # start / restart with a brand-new gateway IP
./opencode-down.sh    # stop
```

To do a full reset (new gateway + new UUID):
```bash
bash reset-network.sh
```

## Verification
Each `opencode-up.sh` run reports:
- **Gateway IP** — changes every cycle (e.g. 172.33.0.1 → 172.192.0.1 → 172.119.0.1)
- **Container IP** — new on each cycle (network .2 of the random subnet)
- **UUID** — new on every startup (written to `storage/uuid.txt`)

Web UI: `http://localhost:3000`

## Note
If you run `docker compose` directly it will fail because `opencode-net` is an
external network — always use `opencode-up.sh` / `opencode-down.sh`.