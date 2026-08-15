import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class PlaylistsService {
  private readonly audioBucket: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    config: ConfigService,
  ) {
    this.audioBucket = config.get<string>('SUPABASE_AUDIO_BUCKET') ?? 'audio';
  }

  async create(userId: string, name: string) {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new BadRequestException('Playlist name cannot be empty');
    }
    return this.prisma.playlist.create({
      data: {
        name: trimmed,
        ownerId: userId,
      },
      include: {
        owner: {
          select: { id: true, displayName: true, email: true },
        },
      },
    });
  }

  async listUserPlaylists(userId: string) {
    const playlists = await this.prisma.playlist.findMany({
      where: { ownerId: userId },
      orderBy: { updatedAt: 'desc' },
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
    });

    return playlists.map((p) => {
      const covers = p.tracks
        .map((pt) => pt.track.coverUrl)
        .filter((c): c is string => Boolean(c));
      return {
        id: p.id,
        name: p.name,
        ownerId: p.ownerId,
        owner: p.owner,
        trackCount: p._count.tracks,
        coverUrls: covers,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      };
    });
  }

  async getPlaylistDetails(playlistId: string) {
    const playlist = await this.prisma.playlist.findUnique({
      where: { id: playlistId },
      include: {
        owner: {
          select: { id: true, displayName: true, email: true },
        },
        tracks: {
          orderBy: { position: 'asc' },
          include: {
            track: true,
          },
        },
      },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    const tracksWithAudio = await Promise.all(
      playlist.tracks.map(async (pt) => {
        const track = pt.track;
        let audioUrl: string | null = null;
        if (track.audioStorageKey) {
          audioUrl = await this.storage.createSignedUrl(
            this.audioBucket,
            track.audioStorageKey,
          );
        }
        return {
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          durationMs: track.durationMs,
          coverUrl: track.coverUrl,
          audioUrl,
          position: pt.position,
        };
      }),
    );

    return {
      id: playlist.id,
      name: playlist.name,
      ownerId: playlist.ownerId,
      owner: playlist.owner,
      trackCount: playlist.tracks.length,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      tracks: tracksWithAudio,
    };
  }

  async renamePlaylist(userId: string, playlistId: string, name: string) {
    const trimmed = name.trim();
    if (!trimmed) {
      throw new BadRequestException('Playlist name cannot be empty');
    }

    const playlist = await this.prisma.playlist.findUnique({
      where: { id: playlistId },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.ownerId !== userId) {
      throw new ForbiddenException('You cannot rename this playlist');
    }

    return this.prisma.playlist.update({
      where: { id: playlistId },
      data: { name: trimmed },
    });
  }

  async deletePlaylist(userId: string, playlistId: string) {
    const playlist = await this.prisma.playlist.findUnique({
      where: { id: playlistId },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.ownerId !== userId) {
      throw new ForbiddenException('You cannot delete this playlist');
    }

    await this.prisma.playlist.delete({
      where: { id: playlistId },
    });

    return { success: true };
  }

  async addTrackToPlaylist(
    userId: string,
    playlistId: string,
    trackId: string,
  ) {
    const playlist = await this.prisma.playlist.findUnique({
      where: { id: playlistId },
      include: { tracks: true },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.ownerId !== userId) {
      throw new ForbiddenException('You cannot edit this playlist');
    }

    const track = await this.prisma.track.findUnique({
      where: { id: trackId },
    });

    if (!track) {
      throw new NotFoundException('Track not found');
    }

    const alreadyInPlaylist = playlist.tracks.some(
      (pt) => pt.trackId === trackId,
    );
    if (alreadyInPlaylist) {
      return { success: true, message: 'Track already in playlist' };
    }

    const maxPosition = playlist.tracks.reduce(
      (max, pt) => (pt.position > max ? pt.position : max),
      -1,
    );

    await this.prisma.playlistTrack.create({
      data: {
        playlistId,
        trackId,
        position: maxPosition + 1,
      },
    });

    await this.prisma.playlist.update({
      where: { id: playlistId },
      data: { updatedAt: new Date() },
    });

    return { success: true };
  }

  async removeTrackFromPlaylist(
    userId: string,
    playlistId: string,
    trackId: string,
  ) {
    const playlist = await this.prisma.playlist.findUnique({
      where: { id: playlistId },
    });

    if (!playlist) {
      throw new NotFoundException('Playlist not found');
    }

    if (playlist.ownerId !== userId) {
      throw new ForbiddenException('You cannot edit this playlist');
    }

    await this.prisma.playlistTrack.deleteMany({
      where: {
        playlistId,
        trackId,
      },
    });

    await this.prisma.playlist.update({
      where: { id: playlistId },
      data: { updatedAt: new Date() },
    });

    return { success: true };
  }

  async likeTrack(userId: string, trackId: string) {
    const track = await this.prisma.track.findUnique({
      where: { id: trackId },
    });

    if (!track) {
      throw new NotFoundException('Track not found');
    }

    await this.prisma.likedTrack.upsert({
      where: {
        userId_trackId: {
          userId,
          trackId,
        },
      },
      create: {
        userId,
        trackId,
      },
      update: {},
    });

    return { success: true, liked: true };
  }

  async unlikeTrack(userId: string, trackId: string) {
    await this.prisma.likedTrack.deleteMany({
      where: {
        userId,
        trackId,
      },
    });

    return { success: true, liked: false };
  }

  async getLikedTracks(userId: string) {
    const liked = await this.prisma.likedTrack.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        track: true,
      },
    });

    return Promise.all(
      liked.map(async (item) => {
        const track = item.track;
        let audioUrl: string | null = null;
        if (track.audioStorageKey) {
          audioUrl = await this.storage.createSignedUrl(
            this.audioBucket,
            track.audioStorageKey,
          );
        }
        return {
          id: track.id,
          title: track.title,
          artist: track.artist,
          album: track.album,
          durationMs: track.durationMs,
          coverUrl: track.coverUrl,
          audioUrl,
          likedAt: item.createdAt,
        };
      }),
    );
  }
}
