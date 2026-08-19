# Sequence Diagram — User Authentication (Login + Token Refresh)

> Follows UML 2.5 conventions. Shows the complete email/password login flow,
> protected API request handling, and automatic silent token refresh on expiry.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as Flutter App
    participant API as NestJS API
    participant DB as PostgreSQL
    participant Store as SecureStorage

    Note over User, Store: ── Phase 1: Email/Password Login ──

    User->>App: Enter email and password, tap Log In
    App->>App: Validate form (non-empty, email regex)
    App->>API: POST /auth/login {email, password}
    API->>DB: SELECT user WHERE email = ?
    DB-->>API: User row (with passwordHash)
    API->>API: bcrypt.compare(password, passwordHash)

    alt Invalid credentials
        API-->>App: 401 Unauthorized
        App-->>User: Show snackbar "Invalid email or password"
    else Valid credentials
        API->>API: sign accessToken (JWT, exp: 15m)
        API->>API: sign refreshToken (JWT, type=refresh, exp: 30d)
        API-->>App: 200 OK {user, accessToken, refreshToken}
        App->>Store: Persist accessToken + refreshToken
        App-->>User: Navigate to HomeScreen
    end

    Note over User, Store: ── Phase 2: Authenticated API Request ──

    User->>App: Trigger protected action (e.g. browse tracks)
    App->>Store: Read accessToken
    App->>API: GET /tracks [Authorization: Bearer accessToken]
    API->>API: JwtAuthGuard.verify(accessToken)

    alt Token is valid
        API->>DB: SELECT * FROM Track ORDER BY createdAt DESC
        DB-->>API: Track rows
        API-->>App: 200 OK Track[]
        App-->>User: Render track list
    else Token expired (401 Unauthorized)
        App->>Store: Read refreshToken
        App->>API: POST /auth/refresh {refreshToken}
        API->>API: jwt.verify(refreshToken, { type: 'refresh' })
        API->>DB: SELECT user WHERE id = payload.sub
        DB-->>API: User row
        API->>API: Issue new accessToken + refreshToken
        API-->>App: 200 OK {accessToken, refreshToken}
        App->>Store: Overwrite tokens with new pair
        App->>API: Retry: GET /tracks [new accessToken]
        API->>DB: SELECT * FROM Track
        DB-->>API: Track rows
        API-->>App: 200 OK Track[]
        App-->>User: Render track list
    end
```

## Key Design Decisions

| Decision | Detail |
|----------|--------|
| **Access Token TTL** | 15 minutes — short-lived to limit exposure if intercepted |
| **Refresh Token TTL** | 30 days — stored securely in device `flutter_secure_storage` |
| **Silent refresh** | The client automatically retries any failed 401 request after refreshing — no user interaction needed |
| **Refresh token type claim** | Refresh tokens carry `type: 'refresh'` in their payload, preventing access tokens from being used as refresh tokens |
