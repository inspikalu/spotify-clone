import { Test } from '@nestjs/testing';
import {
  BadRequestException,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fsp } from 'fs';
import { writeFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { TracksService, UploadedFile } from './tracks.service';

function writeWav(path: string, seconds = 1, sampleRate = 16000): void {
  const byteRate = sampleRate * 2;
  const dataSize = seconds * byteRate;
  const buffer = Buffer.alloc(44 + dataSize);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);
  writeFileSync(path, buffer);
}

function drainStream(stream: unknown): Promise<void> {
  const readable = stream as NodeJS.ReadableStream;
  return new Promise((resolve) => {
    readable.on('error', () => resolve());
    readable.on('end', () => resolve());
    readable.resume();
  });
}

function storageMock() {
  const uploadObject = jest.fn();
  const lastStream = () =>
    uploadObject.mock.calls[uploadObject.mock.calls.length - 1][2];
  uploadObject.mockImplementation(async () => {
    await drainStream(lastStream());
  });
  const rejectingUpload = (err: unknown) => async () => {
    await drainStream(lastStream());
    throw err;
  };
  return {
    uploadObject,
    rejectingUpload,
    createSignedUrl: jest.fn(),
    publicUrl: jest.fn(),
    deleteObject: jest.fn().mockResolvedValue(undefined),
  };
}

function prismaMock() {
  return {
    track: {
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      findMany: jest.fn(),
    },
  };
}

describe('TracksService', () => {
  let service: TracksService;
  let storage: ReturnType<typeof storageMock>;
  let prisma: ReturnType<typeof prismaMock>;
  let audioPath: string;
  let coverPath: string;

  beforeEach(async () => {
    jest.clearAllMocks();
    storage = storageMock();
    prisma = prismaMock();
    audioPath = join(tmpdir(), `spec-audio-${Date.now()}.wav`);
    coverPath = join(tmpdir(), `spec-cover-${Date.now()}.png`);
    writeWav(audioPath);
    writeFileSync(coverPath, Buffer.from('fake-png'));
    const module = await Test.createTestingModule({
      providers: [
        TracksService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storage },
        {
          provide: ConfigService,
          useValue: new ConfigService({
            SUPABASE_AUDIO_BUCKET: 'audio',
            SUPABASE_COVERS_BUCKET: 'covers',
          }),
        },
      ],
    }).compile();
    service = module.get(TracksService);
  });

  afterEach(async () => {
    await fsp.unlink(audioPath).catch(() => undefined);
    await fsp.unlink(coverPath).catch(() => undefined);
  });

  const audioFile = (): UploadedFile => ({
    path: audioPath,
    mimetype: 'audio/wav',
    originalname: 'test.wav',
    size: 32044,
  });

  it('creates the row with a real parsed duration and uploads to storage', async () => {
    prisma.track.create.mockResolvedValue({
      id: 't1',
      title: 'Song',
      artist: 'Artist',
      album: null,
      durationMs: null,
      coverUrl: null,
      audioStorageKey: null,
      ownerId: 'u1',
      createdAt: new Date(),
    });
    prisma.track.update.mockResolvedValue({});
    storage.createSignedUrl.mockResolvedValue('http://storage/signed-audio');

    const result = await service.createTrack('u1', audioFile(), undefined, {
      title: 'Song',
      artist: 'Artist',
    });

    expect(prisma.track.create).toHaveBeenCalledWith({
      data: {
        title: 'Song',
        artist: 'Artist',
        album: null,
        durationMs: expect.any(Number),
        ownerId: 'u1',
      },
    });
    const createdData = prisma.track.create.mock.calls[0][0].data;
    expect(createdData.durationMs).toBeGreaterThanOrEqual(900);
    expect(createdData.durationMs).toBeLessThanOrEqual(1100);
    expect(storage.uploadObject).toHaveBeenCalledWith(
      'audio',
      'audio/t1.wav',
      expect.anything(),
      'audio/wav',
    );
    expect(prisma.track.update).toHaveBeenCalledWith({
      where: { id: 't1' },
      data: { audioStorageKey: 'audio/t1.wav', coverUrl: null },
    });
    expect(result.audioUrl).toBe('http://storage/signed-audio');
  });

  it('deletes the row and temp file when the audio upload fails', async () => {
    prisma.track.create.mockResolvedValue({
      id: 't1',
      title: 'Song',
      artist: 'Artist',
      album: null,
      durationMs: 1000,
      coverUrl: null,
      audioStorageKey: null,
      ownerId: 'u1',
      createdAt: new Date(),
    });
    storage.uploadObject.mockImplementation(
      storage.rejectingUpload(
        new InternalServerErrorException('Storage request failed'),
      ),
    );

    await expect(
      service.createTrack('u1', audioFile(), undefined, {
        title: 'Song',
        artist: 'Artist',
      }),
    ).rejects.toThrow(InternalServerErrorException);
    expect(prisma.track.delete).toHaveBeenCalledWith({ where: { id: 't1' } });
    try {
      await expect(fsp.access(audioPath)).rejects.toThrow();
    } catch (e2) {
      console.log('ACCESS-CHECK STACK:', (e2 as Error).stack);
      throw e2;
    }
    console.log('AFTER access check');
  });

  it('rolls back the audio object and row when the cover upload fails', async () => {
    prisma.track.create.mockResolvedValue({
      id: 't1',
      title: 'Song',
      artist: 'Artist',
      album: null,
      durationMs: 1000,
      coverUrl: null,
      audioStorageKey: null,
      ownerId: 'u1',
      createdAt: new Date(),
    });
    storage.uploadObject.mockImplementationOnce(async () => {
      await drainStream(storage.uploadObject.mock.calls[0][2]);
    });
    storage.uploadObject.mockImplementation(
      storage.rejectingUpload(
        new InternalServerErrorException('Storage request failed'),
      ),
    );

    await expect(
      service.createTrack(
        'u1',
        audioFile(),
        {
          path: coverPath,
          mimetype: 'image/png',
          originalname: 'c.png',
          size: 9,
        },
        { title: 'Song', artist: 'Artist' },
      ),
    ).rejects.toThrow(InternalServerErrorException);
    expect(storage.deleteObject).toHaveBeenCalledWith('audio', 'audio/t1.wav');
    expect(prisma.track.delete).toHaveBeenCalledWith({ where: { id: 't1' } });
  });

  it('rejects oversized covers before parsing', async () => {
    await expect(
      service.createTrack(
        'u1',
        audioFile(),
        {
          path: coverPath,
          mimetype: 'image/png',
          originalname: 'big.png',
          size: 5 * 1024 * 1024 + 1,
        },
        { title: 'Song', artist: 'Artist' },
      ),
    ).rejects.toThrow(BadRequestException);
    expect(prisma.track.create).not.toHaveBeenCalled();
  });
});

describe('TracksService.listTracks', () => {
  let service: TracksService;
  let storage: ReturnType<typeof storageMock>;
  let prisma: ReturnType<typeof prismaMock>;

  beforeEach(async () => {
    storage = storageMock();
    prisma = prismaMock();
    const module = await Test.createTestingModule({
      providers: [
        TracksService,
        { provide: PrismaService, useValue: prisma },
        { provide: StorageService, useValue: storage },
        {
          provide: ConfigService,
          useValue: new ConfigService({
            SUPABASE_AUDIO_BUCKET: 'audio',
            SUPABASE_COVERS_BUCKET: 'covers',
          }),
        },
      ],
    }).compile();
    service = module.get(TracksService);
  });

  it('mints a signed URL per stored track and passes tracks without a key through with null audioUrl', async () => {
    prisma.track.findMany.mockResolvedValue([
      {
        id: 't1',
        title: 'A',
        artist: 'X',
        album: null,
        durationMs: 1000,
        coverUrl: 'http://covers/1.png',
        audioStorageKey: 'audio/t1.mp3',
        ownerId: 'u1',
        createdAt: new Date(),
      },
      {
        id: 't2',
        title: 'B',
        artist: 'Y',
        album: null,
        durationMs: null,
        coverUrl: null,
        audioStorageKey: null,
        ownerId: 'u1',
        createdAt: new Date(),
      },
    ]);
    storage.createSignedUrl.mockResolvedValue('http://storage/signed');

    const result = await service.listTracks('u1');

    expect(storage.createSignedUrl).toHaveBeenCalledTimes(1);
    expect(result[0].audioUrl).toBe('http://storage/signed');
    expect(result[1].audioUrl).toBeNull();
  });
});
