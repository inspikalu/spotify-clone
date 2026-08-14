import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { TokenExpiredError } from 'jsonwebtoken';
import { ResetTokenService } from './reset-token.service';

const config = {
  get: (key: string) => (key === 'RESET_TOKEN_TTL' ? '15m' : undefined),
} as unknown as ConfigService;

describe('ResetTokenService', () => {
  it('sign returns a token that verify accepts, carrying the email', async () => {
    const service = new ResetTokenService(
      new JwtService({ secret: 'test-secret' }),
      config,
    );
    const token = await service.sign('user@test.local');
    await expect(service.verify(token)).resolves.toMatchObject({
      email: 'user@test.local',
      purpose: 'password_reset',
    });
  });

  it('verify rejects a token signed for a different purpose', async () => {
    const jwt = new JwtService({ secret: 'test-secret' });
    const service = new ResetTokenService(jwt, config);
    const token = await jwt.signAsync({
      email: 'user@test.local',
      purpose: 'other',
    });
    await expect(service.verify(token)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('verify rejects a garbage token', async () => {
    const service = new ResetTokenService(
      new JwtService({ secret: 'test-secret' }),
      config,
    );
    await expect(service.verify('not-a-jwt')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('verify rejects an expired token', async () => {
    const jwtMock = {
      verifyAsync: jest
        .fn()
        .mockRejectedValue(new TokenExpiredError('jwt expired', new Date())),
    } as unknown as JwtService;
    const service = new ResetTokenService(jwtMock, config);
    await expect(service.verify('expired-token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
