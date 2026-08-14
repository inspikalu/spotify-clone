import {
  BadRequestException,
  Controller,
  Get,
  Post,
  Req,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import type { Options } from 'multer';
import { Request } from 'express';
import { extname } from 'path';
import { randomUUID } from 'crypto';
import { tmpdir } from 'os';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  AUDIO_MIME_EXT,
  IMAGE_MIME_RE,
  TracksService,
  UploadedFile,
} from './tracks.service';

function asTrimmedString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

export function multerDiskOptions(): Options {
  return {
    storage: diskStorage({
      destination: tmpdir(),
      filename: (_req, file, cb) =>
        cb(null, `spotify-${randomUUID()}${extname(file.originalname)}`),
    }),
    limits: { fileSize: 100 * 1024 * 1024 },
    fileFilter: (_req, file, cb) => {
      if (file.fieldname === 'file') {
        cb(null, AUDIO_MIME_EXT[file.mimetype] !== undefined);
        return;
      }
      if (file.fieldname === 'cover') {
        cb(null, IMAGE_MIME_RE.test(file.mimetype));
        return;
      }
      cb(null, false);
    },
  };
}

interface AuthRequest extends Request {
  user: { userId: string; email: string };
}

@Controller('tracks')
@UseGuards(JwtAuthGuard)
export class TracksController {
  constructor(private readonly tracksService: TracksService) {}

  @Post()
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'file', maxCount: 1 },
        { name: 'cover', maxCount: 1 },
      ],
      multerDiskOptions(),
    ),
  )
  async upload(
    @Req() req: AuthRequest,
    @UploadedFiles()
    files: { file?: UploadedFile[]; cover?: UploadedFile[] },
  ) {
    const audio = files?.file?.[0];
    if (!audio) {
      throw new BadRequestException('Audio file is required');
    }
    const cover = files?.cover?.[0];
    const body = (req.body ?? {}) as Record<string, unknown>;
    const title = asTrimmedString(body.title);
    const artist = asTrimmedString(body.artist);
    const album = asTrimmedString(body.album) || undefined;
    if (!title) {
      throw new BadRequestException('Title is required');
    }
    if (!artist) {
      throw new BadRequestException('Artist is required');
    }
    if (!AUDIO_MIME_EXT[audio.mimetype]) {
      throw new BadRequestException('Unsupported audio type');
    }
    if (cover && !IMAGE_MIME_RE.test(cover.mimetype)) {
      throw new BadRequestException('Cover must be a jpeg, png or webp image');
    }
    const track = await this.tracksService.createTrack(
      req.user.userId,
      audio,
      cover,
      { title, artist, album },
    );
    return track;
  }

  @Get()
  async list(@Req() req: AuthRequest) {
    return this.tracksService.listTracks(req.user.userId);
  }
}
