import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { PlaylistsService } from './playlists.service';

describe('PlaylistsService', () => {
  let service: PlaylistsService;
  let prisma: {
    playlist: {
      create: jest.Mock;
      findMany: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
    track: {
      findUnique: jest.Mock;
    };
    playlistTrack: {
      create: jest.Mock;
      deleteMany: jest.Mock;
    };
    likedTrack: {
      upsert: jest.Mock;
      deleteMany: jest.Mock;
      findMany: jest.Mock;
    };
  };
  let storage: {
    createSignedUrl: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      playlist: {
        create: jest.fn(),
        findMany: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      track: {
        findUnique: jest.fn(),
      },
      playlistTrack: {
        create: jest.fn(),
        deleteMany: jest.fn(),
      },
      likedTrack: {
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findMany: jest.fn(),
      },
    };
    storage = {
      createSignedUrl: jest
        .fn()
        .mockResolvedValue('http://signed.local/audio.mp3'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlaylistsService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storage },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue('audio'),
          },
        },
      ],
    }).compile();

    service = module.get<PlaylistsService>(PlaylistsService);
  });

  describe('create', () => {
    it('creates a playlist with trimmed name and owner', async () => {
      prisma.playlist.create.mockResolvedValue({
        id: 'p1',
        name: 'My Playlist',
        ownerId: 'u1',
        owner: { id: 'u1', email: 'u1@test.com' },
      });

      const res = await service.create('u1', '  My Playlist  ');
      expect(prisma.playlist.create).toHaveBeenCalledWith({
        data: { name: 'My Playlist', ownerId: 'u1' },
        include: {
          owner: { select: { id: true, displayName: true, email: true } },
        },
      });
      expect(res.name).toBe('My Playlist');
    });

    it('rejects empty name', async () => {
      await expect(service.create('u1', '   ')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('listUserPlaylists', () => {
    it('returns formatted user playlists with cover previews', async () => {
      prisma.playlist.findMany.mockResolvedValue([
        {
          id: 'p1',
          name: 'P1',
          ownerId: 'u1',
          owner: { id: 'u1', email: 'u1@test.com' },
          tracks: [
            { track: { id: 't1', coverUrl: 'http://c1.jpg' } },
            { track: { id: 't2', coverUrl: null } },
          ],
          _count: { tracks: 2 },
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);

      const res = await service.listUserPlaylists('u1');
      expect(res).toHaveLength(1);
      expect(res[0].trackCount).toBe(2);
      expect(res[0].coverUrls).toEqual(['http://c1.jpg']);
    });
  });

  describe('getPlaylistDetails', () => {
    it('returns playlist with tracks and signed audio URLs', async () => {
      prisma.playlist.findUnique.mockResolvedValue({
        id: 'p1',
        name: 'P1',
        ownerId: 'u1',
        owner: { id: 'u1', email: 'u1@test.com' },
        tracks: [
          {
            position: 0,
            track: {
              id: 't1',
              title: 'Song 1',
              artist: 'Artist 1',
              audioStorageKey: 'audio/t1.mp3',
            },
          },
        ],
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await service.getPlaylistDetails('p1');
      expect(res.tracks).toHaveLength(1);
      expect(res.tracks[0].audioUrl).toBe('http://signed.local/audio.mp3');
    });

    it('throws NotFoundException on missing playlist', async () => {
      prisma.playlist.findUnique.mockResolvedValue(null);
      await expect(service.getPlaylistDetails('bad')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('renamePlaylist', () => {
    it('renames playlist when owner matches', async () => {
      prisma.playlist.findUnique.mockResolvedValue({ id: 'p1', ownerId: 'u1' });
      prisma.playlist.update.mockResolvedValue({ id: 'p1', name: 'New Name' });

      const res = await service.renamePlaylist('u1', 'p1', 'New Name');
      expect(res.name).toBe('New Name');
    });

    it('throws ForbiddenException if not owner', async () => {
      prisma.playlist.findUnique.mockResolvedValue({ id: 'p1', ownerId: 'u2' });
      await expect(
        service.renamePlaylist('u1', 'p1', 'New Name'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('deletePlaylist', () => {
    it('deletes playlist when owner matches', async () => {
      prisma.playlist.findUnique.mockResolvedValue({ id: 'p1', ownerId: 'u1' });
      prisma.playlist.delete.mockResolvedValue({ id: 'p1' });

      const res = await service.deletePlaylist('u1', 'p1');
      expect(res.success).toBe(true);
    });

    it('throws ForbiddenException if not owner', async () => {
      prisma.playlist.findUnique.mockResolvedValue({ id: 'p1', ownerId: 'u2' });
      await expect(service.deletePlaylist('u1', 'p1')).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('addTrackToPlaylist & removeTrack', () => {
    it('appends track at next position', async () => {
      prisma.playlist.findUnique.mockResolvedValue({
        id: 'p1',
        ownerId: 'u1',
        tracks: [{ trackId: 't1', position: 0 }],
      });
      prisma.track.findUnique.mockResolvedValue({ id: 't2' });
      prisma.playlistTrack.create.mockResolvedValue({ id: 'pt2' });
      prisma.playlist.update.mockResolvedValue({});

      const res = await service.addTrackToPlaylist('u1', 'p1', 't2');
      expect(res.success).toBe(true);
      expect(prisma.playlistTrack.create).toHaveBeenCalledWith({
        data: { playlistId: 'p1', trackId: 't2', position: 1 },
      });
    });

    it('removes track from playlist', async () => {
      prisma.playlist.findUnique.mockResolvedValue({ id: 'p1', ownerId: 'u1' });
      prisma.playlistTrack.deleteMany.mockResolvedValue({ count: 1 });
      prisma.playlist.update.mockResolvedValue({});

      const res = await service.removeTrackFromPlaylist('u1', 'p1', 't1');
      expect(res.success).toBe(true);
      expect(prisma.playlistTrack.deleteMany).toHaveBeenCalledWith({
        where: { playlistId: 'p1', trackId: 't1' },
      });
    });
  });

  describe('likeTrack & unlikeTrack & getLikedTracks', () => {
    it('upserts liked track and lists with signed audio URLs', async () => {
      prisma.track.findUnique.mockResolvedValue({ id: 't1' });
      prisma.likedTrack.upsert.mockResolvedValue({ id: 'l1' });

      const likeRes = await service.likeTrack('u1', 't1');
      expect(likeRes.liked).toBe(true);

      prisma.likedTrack.findMany.mockResolvedValue([
        {
          createdAt: new Date(),
          track: {
            id: 't1',
            title: 'T1',
            artist: 'A1',
            audioStorageKey: 'audio/t1.mp3',
          },
        },
      ]);

      const listRes = await service.getLikedTracks('u1');
      expect(listRes).toHaveLength(1);
      expect(listRes[0].audioUrl).toBe('http://signed.local/audio.mp3');

      prisma.likedTrack.deleteMany.mockResolvedValue({ count: 1 });
      const unlikeRes = await service.unlikeTrack('u1', 't1');
      expect(unlikeRes.liked).toBe(false);
    });
  });
});
