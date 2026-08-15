import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SearchService } from './search.service';

interface AuthenticatedUser {
  userId: string;
  email: string;
}

@Controller('search')
@UseGuards(JwtAuthGuard)
export class SearchController {
  constructor(private readonly searchService: SearchService) {}

  @Get()
  async search(
    @Req() req: Request & { user: AuthenticatedUser },
    @Query('q') query?: string,
  ) {
    const q = query ?? '';
    return this.searchService.search(req.user.userId, q);
  }
}
