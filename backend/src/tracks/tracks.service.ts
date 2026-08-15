import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createReadStream } from 'fs';
import { promises as fsp } from 'fs';
import { parseFile } from 'music-metadata';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';

export const AUDIO_MIME_EXT: Record<string, string> = {
  'audio/mpeg': 'mp3',
  'audio/mp4': 'm4a',
  'audio/x-m4a': 'm4a',
  'audio/wav': 'wav',
  'audio/ogg': 'ogg',
  'audio/flac': 'flac',
  'audio/aac': 'aac',
  'audio/webm': 'webm',
};

export const IMAGE_MIME_RE = /^image\/(jpeg|png|webp)$/;

export const MAX_AUDIO_BYTES = 100 * 1024 * 1024;
export const MAX_COVER_BYTES = 5 * 1024 * 1024;

export interface UploadedFile {
  path: string;
  mimetype: string;
  originalname: string;
  size: number;
}

@Injectable()
export class TracksService {
  private readonly audioBucket: string;
  private readonly coversBucket: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    config: ConfigService,
  ) {
    this.audioBucket = config.get<string>('SUPABASE_AUDIO_BUCKET') ?? 'audio';
    this.coversBucket =
      config.get<string>('SUPABASE_COVERS_BUCKET') ?? 'covers';
  }

  private async extractDurationMs(filePath: string): Promise<number | null> {
    try {
      const metadata = await parseFile(filePath);
      return metadata.format.duration
        ? Math.round(metadata.format.duration * 1000)
        : null;
    } catch {
      return null;
    }
  }

  async createTrack(
    userId: string,
    audio: UploadedFile,
    cover: UploadedFile | undefined,
    dto: { title: string; artist: string; album?: string },
  ): Promise<{
    id: string;
    title: string;
    artist: string;
    album: string | null;
    durationMs: number | null;
    coverUrl: string | null;
    audioUrl: string | null;
    audioStorageKey: string | null;
    createdAt: Date;
  }> {
    if (cover && cover.size > MAX_COVER_BYTES) {
      throw new BadRequestException('Cover image must be 5MB or smaller');
    }
    const durationMs = await this.extractDurationMs(audio.path);
    if (durationMs === null) {
      await this.cleanup(audio, cover);
      throw new BadRequestException('Could not read audio duration');
    }

    const ext = AUDIO_MIME_EXT[audio.mimetype];
    const track = await this.prisma.track.create({
      data: {
        title: dto.title,
        artist: dto.artist,
        album: dto.album?.trim() || null,
        durationMs,
        ownerId: userId,
      },
    });

    let audioStorageKey: string | null = null;
    let coverUrl: string | null = null;
    try {
      audioStorageKey = `audio/${track.id}.${ext}`;
      await this.storage.uploadObject(
        this.audioBucket,
        audioStorageKey,
        createReadStream(audio.path),
        audio.mimetype,
      );
      if (cover) {
        const coverExt = cover.mimetype.split('/')[1];
        const coverKey = `covers/${track.id}.${coverExt}`;
        await this.storage.uploadObject(
          this.coversBucket,
          coverKey,
          createReadStream(cover.path),
          cover.mimetype,
        );
        coverUrl = this.storage.publicUrl(this.coversBucket, coverKey);
      }
      await this.prisma.track.update({
        where: { id: track.id },
        data: { audioStorageKey, coverUrl },
      });
    } catch (err) {
      if (err instanceof BadRequestException) {
        throw err;
      }
      await this.prisma.track.delete({ where: { id: track.id } });
      if (audioStorageKey) {
        await this.storage
          .deleteObject(this.audioBucket, audioStorageKey)
          .catch(() => undefined);
      }
      if (err instanceof InternalServerErrorException) {
        throw err;
      }
      throw new InternalServerErrorException('Failed to store upload');
    } finally {
      await this.cleanup(audio, cover);
    }

    const audioUrl = await this.storage.createSignedUrl(
      this.audioBucket,
      audioStorageKey,
    );
    return { ...track, audioStorageKey, coverUrl, audioUrl };
  }

  async listTracks(_userId?: string) {
    const tracks = await this.prisma.track.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return Promise.all(
      tracks.map(async (track) => {
        if (!track.audioStorageKey) {
          return { ...track, audioUrl: null };
        }
        const audioUrl = await this.storage.createSignedUrl(
          this.audioBucket,
          track.audioStorageKey,
        );
        return { ...track, audioUrl };
      }),
    );
  }

  private async cleanup(
    audio: UploadedFile,
    cover: UploadedFile | undefined,
  ): Promise<void> {
    await Promise.all([
      fsp.unlink(audio.path).catch(() => undefined),
      cover ? fsp.unlink(cover.path).catch(() => undefined) : Promise.resolve(),
    ]);
  }
}
