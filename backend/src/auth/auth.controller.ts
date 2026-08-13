import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('signup')
  async signup(
    @Body() body: { email?: string; password?: string; displayName?: string },
  ) {
    if (!body.email || !EMAIL_PATTERN.test(body.email)) {
      return { statusCode: 400, message: 'A valid email is required', path: '/auth/signup' };
    }
    if (!body.password || body.password.length < 8) {
      return { statusCode: 400, message: 'Password must be at least 8 characters', path: '/auth/signup' };
    }
    return this.auth.signup({ email: body.email, password: body.password, displayName: body.displayName });
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() body: { email?: string; password?: string }) {
    return this.auth.login({ email: body.email ?? '', password: body.password ?? '' });
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() body: { refreshToken?: string }) {
    return this.auth.refresh(body.refreshToken ?? '');
  }

  @Post('forgot-password')
  @HttpCode(HttpStatus.ACCEPTED)
  async forgotPassword(@Body() body: { email?: string }) {
    if (body.email) {
      await this.auth.forgotPassword(body.email);
    }
    return { message: 'Check your email' };
  }

  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() body: { token?: string; newPassword?: string }) {
    if (!body.token || !body.newPassword || body.newPassword.length < 8) {
      return { statusCode: 400, message: 'A valid token and password (≥ 8 chars) are required', path: '/auth/reset-password' };
    }
    await this.auth.resetPassword(body.token, body.newPassword);
    return { message: 'Password reset successfully' };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async me(@Req() req: { user: { userId: string; email: string } }) {
    return { id: req.user.userId, email: req.user.email };
  }
}