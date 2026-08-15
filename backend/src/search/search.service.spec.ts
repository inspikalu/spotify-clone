import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SearchService } from './search.service';

describe('SearchService', () => {
  let service: SearchService;
  let prisma: {
    track: { findMany: jest.Mock };
    playlist: { findMany: jest.Mock };
  };
  let storage: { createSignedUrl: jest.Mock };

  beforeEach(async () => {
    prisma = {
      track: { findMany: jest.fn() },
      playlist: { findMany: jest.fn() },
    };
    storage = {
      createSignedUrl: jest
        .fn()
        .mockResolvedValue('http://signed.url/audio.mp3'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SearchService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storage },
        {
          provide: ConfigService,
          useValue: { get: jest.fn().mockReturnValue('audio') },
        },
      ],
    }).compile();

    service = module.get<SearchService>(SearchService);
  });

  it('returns empty result set for blank or whitespace queries', async () => {
    const result = await service.search('user-1', '   ');
    expect(result).toEqual({
      tracks: [],
      playlists: [],
      artists: [],
      albums: [],
    });
    expect(prisma.track.findMany).not.toHaveBeenCalled();
    expect(prisma.playlist.findMany).not.toHaveBeenCalled();
  });

  it('searches tracks across title, artist, and album and generates audio URLs', async () => {
    prisma.track.findMany.mockResolvedValue([
      {
        id: 'track-1',
        title: 'Apala Interlude',
        artist: 'Seyi Vibez',
        album: 'Billion Dollar Baby',
        durationMs: 160000,
        coverUrl: 'http://covers/1.jpg',
        audioStorageKey: 'tracks/1.mp3',
        createdAt: new Date(),
      },
    ]);
    prisma.playlist.findMany.mockResolvedValue([]);

    const result = await service.search('user-1', 'seyi');
    expect(result.tracks).toHaveLength(1);
    expect(result.tracks[0].title).toBe('Apala Interlude');
    expect(result.tracks[0].audioUrl).toBe('http://signed.url/audio.mp3');
    expect(result.artists).toContain('Seyi Vibez');
    expect(storage.createSignedUrl).toHaveBeenCalledWith(
      'audio',
      'tracks/1.mp3',
    );
  });

  it('searches playlists by name and returns ownerDisplayName', async () => {
    prisma.track.findMany.mockResolvedValue([]);
    prisma.playlist.findMany.mockResolvedValue([
      {
        id: 'playlist-1',
        name: 'Afro Hits 2026',
        ownerId: 'user-2',
        owner: {
          id: 'user-2',
          displayName: 'Curator',
          email: 'curator@test.local',
        },
        tracks: [{ track: { id: 't1', coverUrl: 'http://cover.jpg' } }],
        _count: { tracks: 12 },
        createdAt: new Date('2026-08-15'),
      },
    ]);

    const result = await service.search('user-1', 'afro');
    expect(result.playlists).toHaveLength(1);
    expect(result.playlists[0].name).toBe('Afro Hits 2026');
    expect(result.playlists[0].ownerDisplayName).toBe('Curator');
    expect(result.playlists[0].trackCount).toBe(12);
  });
});
