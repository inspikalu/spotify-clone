import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { Resend } from 'resend';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { PasswordService } from './password.service';
import { ResetTokenService } from './reset-token.service';

const env = {
  JWT_SECRET: 'test-secret',
  ACCESS_TOKEN_TTL: '15m',
  REFRESH_TOKEN_TTL: '30d',
  RESET_TOKEN_TTL: '15m',
  RESEND_FROM: 'onboarding@resend.dev',
};

const config = { get: (key: string) => env[key] } as unknown as ConfigService;

describe('AuthService', () => {
  let service: AuthService;
  const jwt = new JwtService({ secret: env.JWT_SECRET });
  const users = {
    findByEmail: jest.fn(),
    findById: jest.fn(),
    create: jest.fn(),
    updatePassword: jest.fn(),
  } as unknown as UsersService;
  const password = {
    hash: jest.fn(async (p: string) => `hashed:${p}`),
    verify: jest.fn(async () => true),
  } as unknown as jest.Mocked<PasswordService>;
  const resetTokens = {
    sign: jest.fn(async () => 'reset-token'),
    verify: jest.fn(),
  } as unknown as ResetTokenService;
  const resend = { emails: { send: jest.fn() } } as unknown as Resend;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: config },
        { provide: UsersService, useValue: users },
        { provide: PasswordService, useValue: password },
        { provide: ResetTokenService, useValue: resetTokens },
        { provide: Resend, useValue: resend },
      ],
    }).compile();
    service = module.get(AuthService);
  });

  it('signup hashes the password and returns user + token pair', async () => {
    users.findByEmail.mockResolvedValue(null);
    users.create.mockImplementation(
      async ({ email, passwordHash, displayName }) => ({
        id: 'u1',
        email,
        passwordHash,
        displayName: displayName ?? null,
        avatarUrl: null,
      }),
    );
    const result = await service.signup({
      email: 'a@b.c',
      password: 'Password123!',
      displayName: 'Ann',
    });
    expect(password.hash).toHaveBeenCalledWith('Password123!');
    expect(result.user.email).toBe('a@b.c');
    expect(result.accessToken).toBeTruthy();
    expect(result.refreshToken).toBeTruthy();
  });

  it('signup with an existing email throws ConflictException', async () => {
    users.findByEmail.mockResolvedValue({ id: 'u0', email: 'a@b.c' });
    await expect(
      service.signup({ email: 'a@b.c', password: 'Password123!' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('login with correct credentials returns a token pair', async () => {
    users.findByEmail.mockResolvedValue({
      id: 'u1',
      email: 'a@b.c',
      passwordHash: 'hash',
      displayName: null,
      avatarUrl: null,
    });
    password.verify.mockResolvedValue(true);
    const result = await service.login({
      email: 'a@b.c',
      password: 'Password123!',
    });
    expect(result.accessToken).toBeTruthy();
    expect(result.refreshToken).toBeTruthy();
  });

  it('login with a wrong password throws UnauthorizedException', async () => {
    users.findByEmail.mockResolvedValue({
      id: 'u1',
      email: 'a@b.c',
      passwordHash: 'hash',
      displayName: null,
      avatarUrl: null,
    });
    password.verify.mockResolvedValue(false);
    await expect(
      service.login({ email: 'a@b.c', password: 'wrong' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('refresh rotates to a new pair and the new access token verifies', async () => {
    users.findById.mockResolvedValue({ id: 'u1', email: 'a@b.c' });
    const oldRefresh = await jwt.signAsync({
      sub: 'u1',
      email: 'a@b.c',
      type: 'refresh',
    });
    const pair = await service.refresh(oldRefresh);
    const decoded = await jwt.verifyAsync(pair.accessToken);
    expect(decoded.sub).toBe('u1');
    const decodedRefresh = await jwt.verifyAsync(pair.refreshToken);
    expect(decodedRefresh.type).toBe('refresh');
  });
});
