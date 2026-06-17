---
name: api-testing
description: >-
  Exercise and inspect REST/HTTP endpoints from the command line with HTTPie
  (or curl) and jq — for backend feature development and bug reproduction. Use
  when the user asks to "call the endpoint", "test the API", "reproduce the 500",
  "check the response", inspect an actuator/health route, or drive a request
  while debugging a Spring Boot controller.
---

# API testing — HTTPie + jq

Reproduce backend bugs and validate new endpoints by hitting them directly and
slicing the JSON response. Pairs with the `api-contract-review` skill (which
reviews the contract; this one exercises it live).

## Tools

```bash
# HTTPie — ergonomic HTTP client
winget install HTTPie.HTTPie      # or: pipx install httpie / choco install httpie
# jq — JSON processor (was not installed by default on this machine)
winget install jqlang.jq          # or: choco install jq / scoop install jq
```

`curl` is the always-available fallback if HTTPie is absent.

## Common requests

```bash
# GET (":" is shorthand for http://localhost)
http GET :8080/api/orders
http :8080/actuator/health

# POST a JSON body (key=value → JSON fields, key:=value → raw/number/bool)
http POST :8080/api/orders symbol=EURUSD quantity:=1000 dryRun:=true

# Auth header / bearer token (token from env, never hard-coded)
http :8080/api/me "Authorization: Bearer $API_TOKEN"

# Show response headers + status for debugging
http --print=Hh :8080/api/orders
```

curl equivalents:

```bash
curl -s -X POST :8080/api/orders -H 'Content-Type: application/json' \
  -d '{"symbol":"EURUSD","quantity":1000}'
```

## Slice the response with jq

```bash
http :8080/api/orders | jq '.[] | {id, status}'      # project fields
http :8080/api/orders | jq '[.[] | select(.status=="OPEN")] | length'  # count
http :8080/api/orders | jq -r '.[].id'               # raw ids, one per line
http :8080/actuator/health | jq '.status'            # drill into nested JSON
```

## Reproduce a bug methodically

1. Capture the failing request (method, path, headers, body) from the report/logs.
2. Replay it with HTTPie; confirm you reproduce the same status/error.
3. Narrow: tweak one field at a time, diff the response with `jq`.
4. After the fix, replay the exact request → confirm the expected response.

## Safety

- Never put secrets on the command line literally — reference env vars (`$API_TOKEN`).
- Default to local (`:8080`); be explicit and cautious before hitting shared/remote envs.
