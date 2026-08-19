import {
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';
import type { SignOptions } from 'jsonwebtoken';
import { UsersService } from '../users/users.service';
import { PasswordService } from './password.service';
import { ResetTokenService } from './reset-token.service';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly users: UsersService,
    private readonly password: PasswordService,
    private readonly resetTokens: ResetTokenService,
    private readonly resend: Resend,
  ) {}

  async signup(data: {
    email: string;
    password: string;
    displayName?: string;
  }) {
    const existing = await this.users.findByEmail(data.email);
    if (existing) {
      throw new ConflictException('An account with this email already exists');
    }
    const passwordHash = await this.password.hash(data.password);
    const user = await this.users.create({
      email: data.email,
      passwordHash,
      displayName: data.displayName,
    });
    const tokens = await this.issueTokenPair(user.id, user.email);
    return { user: this.safeUser(user), ...tokens };
  }

  async login(data: { email: string; password: string }) {
    const user = await this.users.findByEmail(data.email);
    if (
      !user?.passwordHash ||
      !(await this.password.verify(data.password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const tokens = await this.issueTokenPair(user.id, user.email);
    return { user: this.safeUser(user), ...tokens };
  }

  async refresh(refreshToken: string): Promise<TokenPair> {
    let payload: { sub: string; type?: string };
    try {
      payload = await this.jwt.verifyAsync(refreshToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    if (!payload.sub || payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    const user = await this.users.findById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    return this.issueTokenPair(user.id, user.email);
  }

  async forgotPassword(email: string): Promise<void> {
    const user = await this.users.findByEmail(email);
    if (!user) {
      return;
    }
    const token = await this.resetTokens.sign(user.email);
    const backendBaseUrl =
      this.config.get<string>('API_BASE_URL') ??
      'https://spotify-clone-n891.onrender.com';
    const httpsLink = `${backendBaseUrl}/auth/reset?token=${encodeURIComponent(token)}`;
    const deepLink = `spotifyclone://auth/reset?token=${encodeURIComponent(token)}`;

    try {
      const { error } = await this.resend.emails.send({
        from: this.config.get<string>('RESEND_FROM') ?? 'onboarding@resend.dev',
        to: user.email,
        subject: 'Reset your Spotify password',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; background: #121212; color: #ffffff; border-radius: 8px;">
            <h2 style="color: #1DB954; margin-top: 0;">Password Reset Request</h2>
            <p style="color: #b3b3b3; line-height: 1.5;">We received a request to reset your password. Click the button below to reset it in the Spotify app or browser:</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${httpsLink}" style="background-color: #1DB954; color: #000000; font-weight: bold; text-decoration: none; padding: 14px 28px; border-radius: 50px; display: inline-block;">Reset Password</a>
            </div>
            <p style="color: #727272; font-size: 12px; margin-top: 30px;">Direct link: <a href="${httpsLink}" style="color: #1DB954;">${httpsLink}</a></p>
            <p style="color: #727272; font-size: 12px;">If you did not request a password reset, you can safely ignore this email.</p>
          </div>
        `,
      });
      if (error) {
        this.logger.warn(
          `Password reset email delivery failed for ${email}: ${error.message}`,
        );
      }
    } catch (err) {
      this.logger.warn(
        `Password reset email delivery failed for ${email}: ${String(err)}`,
      );
    }
  }

  async resetPassword(token: string, newPassword: string): Promise<void> {
    const { email } = await this.resetTokens.verify(token);
    const user = await this.users.findByEmail(email);
    if (!user) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }
    const passwordHash = await this.password.hash(newPassword);
    await this.users.updatePassword(user.id, passwordHash);
  }

  async issueTokenPair(userId: string, email: string): Promise<TokenPair> {
    const accessExpiresIn = this.config.get<string>(
      'ACCESS_TOKEN_TTL',
    ) as SignOptions['expiresIn'];
    const refreshExpiresIn = this.config.get<string>(
      'REFRESH_TOKEN_TTL',
    ) as SignOptions['expiresIn'];
    const accessToken = await this.jwt.signAsync(
      { sub: userId, email, jti: randomUUID() },
      { expiresIn: accessExpiresIn ?? '15m' },
    );
    const refreshToken = await this.jwt.signAsync(
      { sub: userId, email, type: 'refresh', jti: randomUUID() },
      { expiresIn: refreshExpiresIn ?? '30d' },
    );
    return { accessToken, refreshToken };
  }

  safeUser(user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  }) {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
    };
  }
}
