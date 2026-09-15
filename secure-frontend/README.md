## Frontend Framework Name and Version

- **Framework:** Flutter
- **Version:** 3.44
- **Language:** Dart
- **Package manager / build tool:** pub

## Required Runtime and Package-Manager Versions

- Flutter SDK 3.44 (includes Dart and `pub`)
- No additional package manager installation required — `pub` ships with the Flutter SDK

## Required Installations and Configuration

The following must be running before starting the frontend:

1. **Windows Server 2022 VM** — Active Directory Domain Services, providing the LDAP source Keycloak authenticates against
2. **Keycloak** — running in Podman on the same VM, realm `dmit2015-realm`, reachable at `http://192.168.113.139:8180`
3. **secure-backend** — Laravel API, started with:
```bash
   php artisan serve --host=0.0.0.0 --port=8001
```
   Required so the Android emulator can reach the API at `10.0.2.2:8001`.

## REST API Base URL Configuration

The API base URL is set as a constant in `lib/services/bill_api_service.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8001/restapi/bills';
```

`10.0.2.2` is the Android emulator's special alias for the host machine's `localhost` — since `secure-backend` runs on the same Windows machine as the emulator, this resolves correctly. If running on a physical device instead of an emulator, this would need to be changed to the host machine's actual network IP.




## Identity Provider Configuration

### Client Used by the Flutter App

- **Client ID:** `dmit2015-flutter-client`
- **Client type:** Public (Client authentication: Off) — **no client secret**
- **Grant type:** Direct access grant (`grant_type=password`)

A public client is used here deliberately, rather than reusing the backend's confidential client. A confidential client's secret is only safe when held by something that isn't distributed to end users, like a server. A compiled mobile app doesn't meet that bar, anyone could decompile the APK and extract any string embedded in it, so a "secret" baked into the app wouldn't actually be secret. OAuth2's public client type exists for exactly this case: Keycloak issues a token based on `client_id` plus valid user credentials, with no secret required or expected.

### Login Flow

The login screen (`lib/screens/login_screen.dart`) collects a username and password and passes them to `AuthService.login()`, which POSTs directly to Keycloak's token endpoint:
```POST http://<keycloak-host>:8180/realms/dmit2015-realm/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

client_id=dmit2015-flutter-client
grant_type=password
username=<entered username>
password=<entered password>
```

On success, the returned JWT `access_token` is decoded locally (payload only, no signature check needed client-side, since the backend performs the real verification) to extract `preferred_username` and `realm_access.roles`, and both are held in memory for the duration of the app session via `AuthService`.

### Token Storage and Usage

The access token is stored only in memory (`AuthService.accessToken`, a static field)  never persisted to disk. Every request from `BillApiService` attaches it via an `Authorization: Bearer <token>` header, generated fresh on each call so a logout or account switch is always reflected immediately.

Logging out (`AuthService.logout()`) clears the token, username, and roles, and returns the user to the login screen, at which point no further requests can succeed until a new login occurs.

## Build and run commands

From the `secure-frontend` folder:

```bash
flutter pub get
flutter run
```

## Startup order
Because this app depends on both the identity provider and the secured backend, start things in this order:

1. **Keycloak**  must be running and reachable (LDAP federation to the Windows Server VM must also be up, since login depends on it)
2. **secure-backend** — from `secure-backend`, run:
```bash
   php artisan serve --host=0.0.0.0 --port=8001
```
3. **secure-frontend**  `flutter run`, as above

If Keycloak or `secure-backend` isn't running yet when the app starts, login or bill-loading requests will fail with a connection error rather than a 401/403, this is expected and just means an earlier step in this order wasn't completed.

## Frontend application URL and port

This is a mobile app (Android emulator), not a web app, so there is no browser URL. The app is installed and launched directly on the emulator via `flutter run`.

The app connects to two backend services, both configured as constants in code:

- **secure-backend API:** `http://10.0.2.2:8001/restapi/bills` (`lib/services/bill_api_service.dart`) — `10.0.2.2` is the Android emulator's alias for the host machine, since `secure-backend` runs on the same Windows machine as the emulator
- **Keycloak token endpoint:** `http://192.168.113.139:8180` (`lib/services/auth_service.dart`)  the VM's actual network IP, since Keycloak runs on a separate machine from the emulator/host

## Required test accounts and roles

| Account | Username | Role |
|---|---|---|
| Student A | `sbueno1` | ActiveStudent |
| Student B | `storres1` | ActiveStudent |
| Accounting | `shiggins` | Accounting |


## Complete multi-account testing steps
1. Launch the app. it opens directly on the **Login** screen (no bill data is visible before authenticating).
2. Log in as **Student A** (`sbueno1`). Confirm the bill list shows only bills owned by Student A.
3. Create a new bill as Student A. Confirm it appears in the list immediately after saving.
4. Tap the logout icon (top-right). Confirm the app returns to the Login screen.
5. Log in as **Student B** (`storres1`). Confirm the bill list is different from Student A's — Student B sees only their own bills, not Student A's.
6. Create a bill as Student B, edit one of Student B's existing bills, and delete one, confirming full CRUD works and stays scoped to Student B's own data.
7. Log out, then log in as **Accounting** (`shiggins`). Confirm the bill list now shows **all** bills from both students combined.
8. Confirm the **+ (create)** button and per-bill **delete** icons are not shown while logged in as Accounting, since the Accounting role is read-only per the assignment's RBAC rules. The UI reflects this, and the backend independently enforces it regardless of what the UI shows.
9. Log out again, confirming the token is cleared and the app returns to the Login screen with no bill data accessible until a new login occurs.