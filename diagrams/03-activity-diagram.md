# Activity Diagram with Swimlanes — Track Upload Flow

> Follows UML 2.5 conventions. Swimlanes represent distinct system participants.
> Shows the complete Track Upload flow including validation, storage, database writes, and rollback on failure.

```mermaid
%%{init: {"theme": "base"}}%%
flowchart TD
    Start([🟢 User taps Upload])
    End1([🔴 End — Success])
    End2([🔴 End — Error])

    subgraph FlutterClient ["📱 Swimlane: Flutter Client"]
        A1["Select audio file\n& fill metadata form"]
        A2["Validate inputs:\ntitle & artist required"]
        A3{Valid?}
        A4["Show validation error\nto user"]
        A5["POST multipart/form-data\nto /tracks with JWT header"]
        A14["Display new track\nin home / track list"]
        A15["Show error snackbar"]
    end

    subgraph NestJSBackend ["⚙️ Swimlane: NestJS Backend"]
        B1["JwtAuthGuard\nverifies Bearer token"]
        B2{Token valid?}
        B3["Return 401 Unauthorized"]
        B4["Multer: write uploaded\nfiles to temp disk"]
        B5["Validate MIME types\nand file sizes"]
        B6{Valid?}
        B7["Return 400 Bad Request"]
        B8["Extract audio duration\nvia music-metadata library"]
        B9["Create Track record\nin DB with pending state"]
        B10["Upload audio stream\nto Supabase Storage"]
        B11["Upload cover stream\nto Supabase Storage\n(if provided)"]
        B12["UPDATE Track record:\naudioStorageKey and coverUrl"]
        B13["Generate signed\naudio URL (1 hour TTL)"]
        B14["Return 201 Track JSON\nwith signed URL"]
        B15["Rollback: DELETE Track\nrecord and storage object"]
        B16["Cleanup temp files\nfrom disk"]
    end

    subgraph SupabaseStorage ["☁️ Swimlane: Supabase Storage"]
        C1["Store audio file\nin audio bucket"]
        C2["Store cover image\nin covers bucket"]
        C3["Issue signed URL\nfor audio access"]
    end

    subgraph PostgreSQL ["🗄️ Swimlane: PostgreSQL via Prisma"]
        D1["INSERT Track row"]
        D2["UPDATE Track row\nwith storage keys"]
    end

    Start --> A1
    A1 --> A2 --> A3
    A3 -- No --> A4 --> A1
    A3 -- Yes --> A5
    A5 --> B1 --> B2
    B2 -- No --> B3 --> A15 --> End2
    B2 -- Yes --> B4 --> B5 --> B6
    B6 -- No --> B7 --> A15
    B6 -- Yes --> B8 --> B9
    B9 --> D1
    D1 --> B10
    B10 --> C1
    C1 --> B11
    B11 --> C2
    C2 --> B12
    B12 --> D2
    D2 --> B13
    B13 --> C3
    C3 --> B14 --> B16 --> A14 --> End1
    B10 -- Upload fails --> B15 --> B16 --> A15 --> End2
```

## Swimlane Responsibilities

| Swimlane | Responsibility |
|----------|---------------|
| **Flutter Client** | User input, validation, multipart HTTP request, displaying results or errors |
| **NestJS Backend** | JWT auth guard, file handling via Multer, validation, business logic, orchestration |
| **Supabase Storage** | Persisting audio and cover image files; generating signed access URLs |
| **PostgreSQL** | Persisting Track metadata; rollback-safe two-phase write (INSERT then UPDATE) |
