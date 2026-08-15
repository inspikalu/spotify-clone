import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PlaylistsService } from './playlists.service';

interface AuthRequest extends Request {
  user: { userId: string; email: string };
}

@Controller()
@UseGuards(JwtAuthGuard)
export class PlaylistsController {
  constructor(private readonly playlistsService: PlaylistsService) {}

  @Post('playlists')
  async createPlaylist(
    @Req() req: AuthRequest,
    @Body() body: { name?: string },
  ) {
    if (!body?.name || typeof body.name !== 'string' || !body.name.trim()) {
      throw new BadRequestException('Playlist name cannot be empty');
    }
    return this.playlistsService.create(req.user.userId, body.name);
  }

  @Get('playlists')
  async listPlaylists(@Req() req: AuthRequest) {
    return this.playlistsService.listUserPlaylists(req.user.userId);
  }

  @Get('playlists/:id')
  async getPlaylist(@Param('id') id: string) {
    return this.playlistsService.getPlaylistDetails(id);
  }

  @Patch('playlists/:id')
  async renamePlaylist(
    @Req() req: AuthRequest,
    @Param('id') id: string,
    @Body() body: { name?: string },
  ) {
    if (!body?.name || typeof body.name !== 'string' || !body.name.trim()) {
      throw new BadRequestException('Playlist name cannot be empty');
    }
    return this.playlistsService.renamePlaylist(req.user.userId, id, body.name);
  }

  @Delete('playlists/:id')
  async deletePlaylist(@Req() req: AuthRequest, @Param('id') id: string) {
    return this.playlistsService.deletePlaylist(req.user.userId, id);
  }

  @Post('playlists/:id/tracks')
  async addTrack(
    @Req() req: AuthRequest,
    @Param('id') id: string,
    @Body() body: { trackId?: string },
  ) {
    if (!body?.trackId || typeof body.trackId !== 'string') {
      throw new BadRequestException('trackId is required');
    }
    return this.playlistsService.addTrackToPlaylist(
      req.user.userId,
      id,
      body.trackId,
    );
  }

  @Delete('playlists/:id/tracks/:trackId')
  async removeTrack(
    @Req() req: AuthRequest,
    @Param('id') id: string,
    @Param('trackId') trackId: string,
  ) {
    return this.playlistsService.removeTrackFromPlaylist(
      req.user.userId,
      id,
      trackId,
    );
  }

  @Post('tracks/:id/like')
  async likeTrack(@Req() req: AuthRequest, @Param('id') id: string) {
    return this.playlistsService.likeTrack(req.user.userId, id);
  }

  @Delete('tracks/:id/like')
  async unlikeTrack(@Req() req: AuthRequest, @Param('id') id: string) {
    return this.playlistsService.unlikeTrack(req.user.userId, id);
  }

  @Get('me/liked-tracks')
  async getLikedTracks(@Req() req: AuthRequest) {
    return this.playlistsService.getLikedTracks(req.user.userId);
  }
}
