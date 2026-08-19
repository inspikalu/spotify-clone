# Use Case Diagram — Spotify Clone

> Follows UML 2.5 conventions. Actors are shown outside the system boundary; use cases are inside.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"primaryColor": "#1DB954", "primaryTextColor": "#fff", "primaryBorderColor": "#158a3e", "lineColor": "#555", "secondaryColor": "#191414", "tertiaryColor": "#282828"}}}%%
graph LR
    %% Actors
    GU(["👤 Guest User"])
    AU(["👤 Authenticated User"])
    GS(["☁️ Google OAuth\n(External System)"])
    SB(["☁️ Supabase Storage\n(External System)"])
    RE(["☁️ Resend Email\n(External System)"])

    subgraph SpotifyClone ["🎵  Spotify Clone System"]
        UC1["Register Account"]
        UC2["Log In with Email/Password"]
        UC3["Log In with Google"]
        UC4["Log Out"]
        UC5["Request Password Reset"]
        UC6["Reset Password via Link"]

        UC7["Browse Home Feed"]
        UC8["Search Tracks"]
        UC9["Upload Track"]
        UC10["Play / Pause Track"]
        UC11["Seek & Skip Track"]
        UC12["Like / Unlike Track"]
        UC13["View Liked Tracks"]

        UC14["Create Playlist"]
        UC15["Rename Playlist"]
        UC16["Delete Playlist"]
        UC17["Add Track to Playlist"]
        UC18["Remove Track from Playlist"]
        UC19["View Playlist Detail"]

        UC20["View Now Playing Screen"]
        UC21["Background Audio Playback"]
    end

    %% Guest associations
    GU --> UC1
    GU --> UC2
    GU --> UC3
    GU --> UC5

    %% Authenticated User associations
    AU --> UC4
    AU --> UC6
    AU --> UC7
    AU --> UC8
    AU --> UC9
    AU --> UC10
    AU --> UC11
    AU --> UC12
    AU --> UC13
    AU --> UC14
    AU --> UC15
    AU --> UC16
    AU --> UC17
    AU --> UC18
    AU --> UC19
    AU --> UC20
    AU --> UC21

    %% External system associations
    UC3 --> GS
    UC9 --> SB
    UC10 --> SB
    UC5 --> RE
    UC6 --> RE
```

## Actor Descriptions

| Actor | Role |
|-------|------|
| **Guest User** | Unauthenticated visitor; can register, log in, or request a password reset |
| **Authenticated User** | Logged-in user with full access to all features |
| **Google OAuth** | External identity provider used for social sign-in |
| **Supabase Storage** | External object store for audio files and cover images |
| **Resend Email** | External email delivery service for password reset links |
