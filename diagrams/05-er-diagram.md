# Entity-Relationship (ER) Diagram — Spotify Clone

> Follows standard ER notation with crow's foot cardinality.
> Reflects the Prisma schema (`backend/prisma/schema.prisma`) exactly.

```mermaid
erDiagram
    USER {
        string id PK "CUID, NOT NULL"
        string email UK "UNIQUE, NOT NULL"
        string passwordHash "nullable"
        string displayName "nullable"
        string googleSub UK "UNIQUE, nullable"
        string avatarUrl "nullable"
        datetime createdAt "default: now()"
        datetime updatedAt "auto-updated"
    }

    TRACK {
        string id PK "CUID, NOT NULL"
        string title "NOT NULL"
        string artist "NOT NULL"
        string album "nullable"
        int durationMs "nullable"
        string coverUrl "nullable — public Supabase URL"
        string audioUrl "nullable — deprecated field"
        string audioStorageKey "nullable — Supabase storage path"
        string ownerId FK "references USER.id"
        datetime createdAt "default: now()"
        datetime updatedAt "auto-updated"
    }

    PLAYLIST {
        string id PK "CUID, NOT NULL"
        string name "NOT NULL"
        string ownerId FK "references USER.id"
        datetime createdAt "default: now()"
        datetime updatedAt "auto-updated"
    }

    PLAYLIST_TRACK {
        string id PK "CUID, NOT NULL"
        string playlistId FK "references PLAYLIST.id"
        string trackId FK "references TRACK.id"
        int position "NOT NULL — ordering within playlist"
    }

    LIKED_TRACK {
        string id PK "CUID, NOT NULL"
        string userId FK "references USER.id"
        string trackId FK "references TRACK.id"
        datetime createdAt "default: now()"
    }

    USER ||--o{ TRACK : "owns (ownerId)"
    USER ||--o{ PLAYLIST : "owns (ownerId)"
    USER ||--o{ LIKED_TRACK : "likes (userId)"
    PLAYLIST ||--o{ PLAYLIST_TRACK : "contains (playlistId)"
    TRACK ||--o{ PLAYLIST_TRACK : "referenced by (trackId)"
    TRACK ||--o{ LIKED_TRACK : "liked via (trackId)"
```

## Constraints & Notes

| Table | Constraint | Detail |
|-------|-----------|--------|
| `USER` | `email` UNIQUE | One account per email address |
| `USER` | `googleSub` UNIQUE | One Google identity per account |
| `PLAYLIST_TRACK` | `(playlistId, trackId)` UNIQUE | A track can appear at most once in a playlist |
| `LIKED_TRACK` | `(userId, trackId)` UNIQUE | A user can like a track at most once |
| All FKs | `ON DELETE CASCADE` | Deleting a User removes all their Tracks, Playlists, and Likes |

## Storage Notes

- **Audio files** → Supabase `audio` bucket, keyed as `audio/{trackId}.{ext}`. Access via **signed URLs** (1 hour TTL), regenerated on every list/detail request.
- **Cover images** → Supabase `covers` bucket, keyed as `covers/{trackId}.{ext}`. Access via **permanent public URLs** stored in `TRACK.coverUrl`.
