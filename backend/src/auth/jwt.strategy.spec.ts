import { ConfigService } from '@nestjs/config';
import { UnauthorizedException } from '@nestjs/common';
import { JwtStrategy } from './jwt.strategy';

const config = { get: (key: string) => (key === 'JWT_SECRET' ? 'test-secret' : undefined) } as unknown as ConfigService;

describe('JwtStrategy', () => {
  const strategy = new JwtStrategy(config);

  it('validate maps sub+email to the request user', async () => {
    await expect(strategy.validate({ sub: 'u1', email: 'a@b.c' })).resolves.toEqual({
      userId: 'u1',
      email: 'a@b.c',
    });
  });

  it('validate rejects a payload without sub', async () => {
    await expect(strategy.validate({ email: 'a@b.c' } as never)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
