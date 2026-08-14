import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class GoogleAuthService {
  private readonly client: OAuth2Client;

  constructor(
    private readonly config: ConfigService,
    private readonly users: UsersService,
    private readonly auth: AuthService,
  ) {
    this.client = new OAuth2Client(this.config.get<string>('GOOGLE_CLIENT_ID'));
  }

  async authenticate(idToken: string) {
    if (!idToken) {
      throw new BadRequestException('Missing idToken');
    }
    let payload: {
      sub?: string;
      email?: string;
      name?: string | null;
      picture?: string | null;
    };
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.config.get<string>('GOOGLE_CLIENT_ID'),
      });
      payload = ticket.getPayload() ?? {};
    } catch {
      throw new UnauthorizedException('Invalid Google token');
    }
    if (!payload.sub || !payload.email) {
      throw new UnauthorizedException('Invalid Google token');
    }
    const user = await this.users.upsertGoogle({
      googleSub: payload.sub,
      email: payload.email,
      displayName: payload.name ?? undefined,
      avatarUrl: payload.picture ?? undefined,
    });
    const tokens = await this.auth.issueTokenPair(user.id, user.email);
    return { user: this.auth.safeUser(user), ...tokens };
  }
}
