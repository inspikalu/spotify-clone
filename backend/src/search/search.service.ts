import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

export interface SearchResultsDto {
  tracks: Array<{
    id: string;
    title: string;
    artist: string;
    album: string | null;
    durationMs: number | null;
    coverUrl: string | null;
    audioUrl: string | null;
  }>;
  playlists: Array<{
    id: string;
    name: string;
    ownerId: string;
    ownerDisplayName: string | null;
    trackCount: number;
    coverUrls: string[];
    createdAt: Date;
  }>;
  artists: string[];
  albums: string[];
}

@Injectable()
export class SearchService {
  private readonly audioBucket: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    config: ConfigService,
  ) {
    this.audioBucket = config.get<string>('SUPABASE_AUDIO_BUCKET') ?? 'audio';
  }

  async search(userId: string, query: string): Promise<SearchResultsDto> {
    const trimmed = (query ?? '').trim();
    if (!trimmed) {
      return {
        tracks: [],
        playlists: [],
        artists: [],
        albums: [],
      };
    }

    // 1. Search Tracks by title, artist, or album
    const matchingTracks = await this.prisma.track.findMany({
      where: {
        OR: [
          { title: { contains: trimmed, mode: 'insensitive' } },
          { artist: { contains: trimmed, mode: 'insensitive' } },
          { album: { contains: trimmed, mode: 'insensitive' } },
        ],
      },
      take: 20,
      orderBy: { createdAt: 'desc' },
    });

    const tracksWithSignedUrls = await Promise.all(
      matchingTracks.map(async (track) => {
        let audioUrl: string | null = null;
        if (track.audioStorageKey) {
          try {
            audioUrl = await this.storage.createSignedUrl(
              this.audioBucket,
              track.audioStorageKey,
            );
          } catch {
            audioUrl = null;
          }
        }
        return {
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          durationMs: track.durationMs,
          coverUrl: track.coverUrl,
          audioUrl,
        };
      }),
    );

    // 2. Search Playlists by name (accessible by user or public)
    const matchingPlaylists = await this.prisma.playlist.findMany({
      where: {
        name: { contains: trimmed, mode: 'insensitive' },
      },
      include: {
        owner: {
          select: { id: true, displayName: true, email: true },
        },
        tracks: {
          orderBy: { position: 'asc' },
          include: {
            track: {
              select: { id: true, coverUrl: true },
            },
          },
          take: 4,
        },
        _count: {
          select: { tracks: true },
        },
      },
      take: 10,
      orderBy: { updatedAt: 'desc' },
    });

    const formattedPlaylists = matchingPlaylists.map((p) => {
      const covers = p.tracks
        .map((pt) => pt.track.coverUrl)
        .filter((c): c is string => Boolean(c));
      return {
        id: p.id,
        name: p.name,
        ownerId: p.ownerId,
        ownerDisplayName: p.owner?.displayName ?? p.owner?.email ?? 'User',
        trackCount: p._count.tracks,
        coverUrls: covers,
        createdAt: p.createdAt,
      };
    });

    // 3. Extract distinct matching artists and albums
    const artistsSet = new Set<string>();
    const albumsSet = new Set<string>();

    for (const t of matchingTracks) {
      if (t.artist && t.artist.toLowerCase().includes(trimmed.toLowerCase())) {
        artistsSet.add(t.artist);
      }
      if (t.album && t.album.toLowerCase().includes(trimmed.toLowerCase())) {
        albumsSet.add(t.album);
      }
    }

    return {
      tracks: tracksWithSignedUrls,
      playlists: formattedPlaylists,
      artists: Array.from(artistsSet),
      albums: Array.from(albumsSet),
    };
  }
}
