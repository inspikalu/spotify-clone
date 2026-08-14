import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import type { SignOptions } from 'jsonwebtoken';

const RESET_PURPOSE = 'password_reset';

export interface ResetTokenPayload {
  email: string;
  purpose: string;
}

@Injectable()
export class ResetTokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  sign(email: string): Promise<string> {
    const ttl = this.config.get<string>(
      'RESET_TOKEN_TTL',
    ) as SignOptions['expiresIn'];
    return this.jwt.signAsync(
      { email, purpose: RESET_PURPOSE },
      { expiresIn: ttl ?? '15m' },
    );
  }

  async verify(token: string): Promise<ResetTokenPayload> {
    let payload: ResetTokenPayload;
    try {
      payload = await this.jwt.verifyAsync<ResetTokenPayload>(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired reset token');
    }
    if (payload.purpose !== RESET_PURPOSE || !payload.email) {
      throw new UnauthorizedException('Invalid or expired reset token');
    }
    return payload;
  }
}
