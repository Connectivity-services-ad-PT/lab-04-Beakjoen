# Docker Evidence – Lab 04

## Team

- Team name: team-iot
- Service: IoT Ingestion (FastAPI)
- Image tag: `fit4110/iot-ingestion:lab04` / `fit4110/iot-ingestion:v0.1.0-team-iot`

---

## 1. Build evidence

Command:

```bash
docker build -t fit4110/iot-ingestion:lab04 .
```

Result: SUCCESS – multi-stage build (builder + runtime), image size ~268 MB (63.4 MB content).

Image list:

```
REPOSITORY               TAG               IMAGE ID       SIZE
fit4110/iot-ingestion    lab04             64988b798184   268MB
fit4110/iot-ingestion    v0.1.0-team-iot   64988b798184   268MB
```

---

## 2. Run evidence

Command:

```bash
docker run -d --rm --name fit4110-iot-lab04 -p 8000:8000 --env-file .env.example fit4110/iot-ingestion:lab04
```

Container inspect:

```
User=appuser | Image=fit4110/iot-ingestion:lab04 | Healthcheck=healthy
```

Startup logs:

```
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

---

## 3. Healthcheck evidence

Command:

```bash
Invoke-RestMethod -Uri http://localhost:8000/health
```

Result:

```json
{
  "status": "ok",
  "service": "iot-ingestion",
  "version": "0.4.0"
}
```

Docker healthcheck status: **healthy**

---

## 4. Newman evidence

Command:

```bash
npm run test:local
```

Result summary:

```
iterations:    1 / 0 failed
requests:     11 / 0 failed
test-scripts: 11 / 0 failed
assertions:   19 / 0 failed
total run duration: 997ms
average response time: 7ms
```

All 4 test suites passed:
- ✅ 01_Functional (4 requests, 9 assertions)
- ✅ 02_Auth (2 requests, 2 assertions)
- ✅ 03_Negative (2 requests, 2 assertions)
- ✅ 04_Boundary_Reliability (3 requests, 6 assertions)

Reports:
- `reports/newman-lab04-local.xml`
- `reports/newman-lab04-local.html`

---

## 5. Bug fixes applied

### Issue 1: HTTP_STATUS_CODES compatibility
**Issue:** `status.HTTP_STATUS_CODES` does not exist in `starlette.status` (removed in newer versions).  
**Symptom:** Auth error handler raised `AttributeError` → 500 instead of 401.  
**Fix:** Added a local `_HTTP_STATUS_PHRASES` dict in `src/iot_app/main.py` and replaced all references.

### Issue 2: Container startup timeout in CI
**Issue:** GitHub Actions workflow failed at "Wait for service health" step with 30s timeout.  
**Symptom:** `npx wait-on` timeout error, container not ready in time.  
**Root causes:**
- HEALTHCHECK had `start-period=10s` but workflow only waited 30s total
- CMD used `sh -c` which added startup overhead
- Health check interval was too long (30s)

**Fixes applied:**
1. Improved HEALTHCHECK timing: `interval=10s`, `start-period=5s` (down from 30s and 10s)
2. Created `scripts/entrypoint.sh` for cleaner process management
3. Increased CI wait-on timeout from 30s to 60s
4. Simplified container startup sequence

---

## 6. OpenAPI lint (Spectral)

Command:

```bash
npx spectral lint contracts/iot-ingestion.openapi.yaml
```

Result:

```
✖ 2 problems (0 errors, 2 warnings, 0 infos, 0 hints)
  - info-contact: Info object must have "contact" object.
  - operation-description: missing on GET /readings/{reading_id}
```

0 errors — contract is valid.

---

## 7. Notes

- Bug in original `main.py` fixed: `status.HTTP_STATUS_CODES` → local `_HTTP_STATUS_PHRASES` dict.
- Added `.spectral.yaml` to enable Spectral OAS linting.
- Non-root user `appuser` confirmed via `docker inspect`.
- Next step for Lab 05: wire into Docker Compose multi-service setup.
