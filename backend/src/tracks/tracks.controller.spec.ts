import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { TracksController } from './tracks.controller';
import { TracksService } from './tracks.service';

function serviceMock() {
  return {
    createTrack: jest.fn(),
    listTracks: jest.fn(),
  };
}

describe('TracksController', () => {
  let controller: TracksController;
  let service: ReturnType<typeof serviceMock>;
  const req = (body: Record<string, unknown>) =>
    ({ user: { userId: 'u1', email: 'a@b.c' }, body }) as never;

  const audioFile = {
    path: '/tmp/spotify-x.wav',
    mimetype: 'audio/wav',
    originalname: 'a.wav',
    size: 100,
  };

  beforeEach(async () => {
    service = serviceMock();
    const module = await Test.createTestingModule({
      controllers: [TracksController],
      providers: [
        { provide: TracksService, useValue: service },
        {
          provide: ConfigService,
          useValue: new ConfigService({}),
        },
      ],
    }).compile();
    controller = module.get(TracksController);
  });

  it('rejects when no audio file is present', async () => {
    await expect(
      controller.upload(req({}), { file: [], cover: [] }),
    ).rejects.toThrow('Audio file is required');
    expect(service.createTrack).not.toHaveBeenCalled();
  });

  it('rejects when title is missing', async () => {
    await expect(
      controller.upload(req({ artist: 'Artist' }), {
        file: [audioFile],
        cover: [],
      }),
    ).rejects.toThrow('Title is required');
    expect(service.createTrack).not.toHaveBeenCalled();
  });

  it('rejects a non-image cover', async () => {
    await expect(
      controller.upload(req({ title: 'Song', artist: 'Artist' }), {
        file: [audioFile],
        cover: [
          {
            path: '/tmp/x.txt',
            mimetype: 'text/plain',
            originalname: 'x.txt',
            size: 10,
          },
        ],
      }),
    ).rejects.toThrow('Cover must be a jpeg, png or webp image');
    expect(service.createTrack).not.toHaveBeenCalled();
  });

  it('rejects an unsupported audio mime type', async () => {
    await expect(
      controller.upload(req({ title: 'Song', artist: 'Artist' }), {
        file: [{ ...audioFile, mimetype: 'video/mp4' }],
        cover: [],
      }),
    ).rejects.toThrow('Unsupported audio type');
    expect(service.createTrack).not.toHaveBeenCalled();
  });
});
