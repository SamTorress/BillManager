## Backend Framework Name and Version

- **Framework:** Laravel
- **Version:** 13.8
- **Language:** PHP 8.4.23
- **Database:** PostgreSQL 17
- **Database inspection tool used:** pgAdmin

## Runtime Version

- PHP 8.4.23 (via Laravel Herd)
- Composer 2.x

## Database Configuration and Startup Instructions

The database configuration follows the same pattern as Part 1 — Postgres runs in a Podman container on the course VM. `secure-backend` uses a **separate database**, `dmit2015_secure`, copied from Part 1's `dmit2015_billapi` so existing seeded bill data carries over.

```bash
# Check running containers
podman ps

# If the Postgres container isn't running, start it
podman start dmit2015-postgis

# Confirm it's up
podman ps
```

## Required Environment Variables

In `secure-backend/.env`:

DB_CONNECTION=pgsql
DB_HOST=192.168.113.139
DB_PORT=5432
DB_DATABASE=dmit2015_secure
DB_USERNAME=user2015
DB_PASSWORD=Password2015

KEYCLOAK_JWKS_URL=http://192.168.113.139:8180/realms/dmit2015-realm/protocol/openid-connect/certs

## Identity-Provider Setup

Keycloak realm `dmit2015-realm` is configured with **LDAP User Federation** against Active Directory, running on a separate Windows Server 2022 VM. Keycloak does not store user passwords itself — authentication is delegated entirely to AD.

Since the VM's IP can change between sessions, verify it before each run:

1. On the Windows Server VM, open Command Prompt and run `ipconfig` to get the current IP.
2. In Keycloak → **User Federation** → **Window Server 2022 VM** → **Settings**, update the **Connection URL** if the IP has changed.
3. Click **Test connection**, then attempt a login to confirm authentication also works (occasionally the AD account password itself needs to be reset if it's expired).

## Realm, Client, and Token Configuration

- **Realm:** `dmit2015-realm`
- **Client used for direct backend testing:** `dmit2015-project-client`
  - Client authentication: **On** (confidential — requires a secret)
  - Direct access grants: **On**
  - The client secret is stored only in a local Postman environment variable and is **not committed to this repository**.

> Note: the Flutter frontend (`secure-frontend`) uses a separate **public** client, `dmit2015-flutter-client`, with no secret — appropriate since a compiled mobile app can't safely store one. See `secure-frontend/README.md`.

## Required Roles and Test Accounts

| Account | Username | Role |
|---|---|---|
| Student A | `sbueno1` | ActiveStudent |
| Student B | `storres1` | ActiveStudent |
| Accounting | `shiggins` | Accounting |

## Startup Order

1. Windows Server 2022 VM (AD DS) must be running
2. Postgres container (`podman start dmit2015-postgis`)
3. Keycloak container, reachable at `http://192.168.113.139:8180`
4. `secure-backend` (see Build and Run Commands below)

## Build and Run Commands

```bash
cd secure-backend
composer install
php artisan migrate
php artisan serve --host=0.0.0.0 --port=8001
```

## Application URLs and Ports

- **secure-backend API:** `http://127.0.0.1:8001/restapi`
- **Keycloak:** `http://192.168.113.139:8180`

## Secured Endpoint and Role Summary

| Method | Endpoint | Required Role | Behavior |
|---|---|---|---|
| GET | `/restapi/bills` | ActiveStudent, Accounting | ActiveStudent sees only their own bills; Accounting sees all |
| GET | `/restapi/bills/{id}` | ActiveStudent | Returns the bill only if owned by the caller; 403 otherwise |
| POST | `/restapi/bills` | ActiveStudent | Creates a bill owned by the authenticated user; owner is derived from the JWT, never trusted from the request body |
| PUT | `/restapi/bills/{id}` | ActiveStudent | Updates the bill only if owned by the caller; 403 otherwise |
| DELETE | `/restapi/bills/{id}` | ActiveStudent | Deletes the bill only if owned by the caller; 403 otherwise (Accounting cannot delete under any circumstances) |

## Expected HTTP 401, 403, and 404 Behavior

- **No token provided:** 401
- **Invalid or expired token:** 401
- **Valid token, wrong role for the endpoint:** 403 (e.g. Accounting attempting POST/PUT/DELETE)
- **Valid token, correct role, wrong owner:** 403 (e.g. Student A requesting a bill owned by Student B)

Verified test cases:
- Student A can GET and POST their own bills; gets 403 attempting to access a bill owned by Student B.
- Student B can GET and POST their own bills; gets 403 attempting to access a bill owned by Student A.
- Accounting can GET all bills, but receives 403 on POST, PUT, and DELETE.
- **Ownership spoofing test:** submitted a POST as Student B with `"owner": "sbueno1"` included in the request body. The backend ignored this and correctly assigned the bill to `storres1` (the authenticated user from the JWT), confirming the server never trusts a client-submitted owner value.

## Instructions for Directly Testing the Secured Endpoints

Testing was done with **Postman**. A `Local Laravel` environment was created with the following variables, so requests could be reused across accounts without hardcoding values:

- `baseurl`
- `keycloakurl`
- `realm`
- `clientid`
- `clientsecret`

Three saved requests generate tokens for each test account:

- **POST Get Token - Student A**
- **POST Get Token - Student B**
- **POST Get Token - Accounting**

Each is a `x-www-form-urlencoded` POST to:

{{keycloakurl}}/realms/{{realm}}/protocol/openid-connect/token

with body fields `client_id`, `client_secret`, `grant_type=password`, `username`, `password`.

All five `bills` endpoints were tested against all three accounts to verify the role/ownership rules above.

(Initial testing was done with `curl.exe` from PowerShell, but shell-escaping issues with JSON request bodies made it unreliable for repeated testing — Postman's saved requests and environment variables proved more consistent for this purpose.)

## Sample Authenticated Requests and Expected Responses

**Student B — DELETE `/restapi/bills/21`**
```json
{
    "id": 21,
    "payeeName": "Spoofed Owner Test - Updated",
    "dueDate": "2026-08-15",
    "paymentDue": 99.00,
    "paid": true,
    "version": 0
}
```
Response: `204 No Content`

**Student B — POST `/restapi/bills`**
```json
{
    "id": 22,
    "payeeName": "Greenfield basic",
    "dueDate": "2026-08-15",
    "paymentDue": "499.00",
    "paid": true,
    "version": 0
}
```
Response: `201 Created`

**Accounting — DELETE `/restapi/bills/22`**
Response: `403 Forbidden` (Accounting role does not include delete permission)
