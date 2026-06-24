# Arbitron v3.0.3 — Power User API + Model Dropdown

Two features: an embedded read-only REST API for external integrations, and a
fetchable model dropdown for the LLM config (per PRD §7.1).

## Install
Download `arbitron-v3.0.3.apk` — Android 10+, ~57 MB.
- **Version:** 3.0.3 (versionCode 11) · `com.arbitron.arbitron`

## What's new

### LLM model dropdown (PRD §7.1)
The LLM config screen no longer requires typing a model name manually. Instead:
1. Enter your endpoint and API key
2. Tap **"Fetch available models"** — the app calls `/v1/models` on your
   endpoint and populates a dropdown
3. Select from the list; toggle "Enter manually" if you prefer

If the fetch fails (wrong key, unreachable endpoint), the app shows an error
message and offers manual entry as a fallback. The selected model is saved
with the config.

### Local REST API (PRD §12 v3.0 — API access for power users)
A new "Power User API" section in Settings lets users start/stop an embedded
HTTP server (powered by `shelf`) on port 8765. When enabled:

- **Auth:** a unique token is auto-generated. All requests require
  `Authorization: Bearer <token>`.
- **Endpoints:**
  - `GET /api/v1/status` — feed status, LLM status, counts
  - `GET /api/v1/opportunities` — all live opportunities
  - `GET /api/v1/trades` — complete trade history
  - `GET /api/v1/strategies` — all configured strategies
  - `GET /api/v1/portfolio` — portfolio value, P&L
- **Read-only:** no trade execution via API

### Files added
- `core/data/api_server.dart` — shelf-based REST API server
- `_ModelDropdown` widget in settings

### Changes
- `LlmService.fetchModels()` — calls `/v1/models` endpoint, returns sorted IDs
- `AppCubit.fetchLlmModels()` — delegates to the LLM service
- LLM config sheet: dropdown with fetch button, manual entry toggle, error state
- Settings: "Power User API" section with start/stop toggle and token display

## Verification
- `flutter analyze` → 0 errors, 0 warnings
- `flutter test` → all tests pass
- `flutter build apk --release` → 56.6 MB APK

---

*Cryptocurrency trading involves significant risk of loss. The API is read-only and does not enable trade execution.*