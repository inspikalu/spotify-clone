import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { ResetTokenService } from '../src/auth/reset-token.service';

describe('Auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const email = `e2e-${Date.now()}@test.local`;
  const password = 'Password123!';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
    prisma = moduleRef.get(PrismaService);
  });

  afterAll(async () => {
    await prisma.user.deleteMany({ where: { email: { startsWith: 'e2e-' } } });
    await app.close();
  });

  it('1. signup returns 201 with user and token pair', async () => {
    const res = await request(app.getHttpServer()).post('/auth/signup').send({
      email,
      password,
      displayName: 'E2E User',
    });
    expect(res.status).toBe(201);
    expect(res.body.user.email).toBe(email);
    expect(res.body.accessToken).toBeTruthy();
    expect(res.body.refreshToken).toBeTruthy();
  });

  it('2. duplicate signup returns 409', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({ email, password });
    expect(res.status).toBe(409);
  });

  it('3. login with correct credentials returns 200 + tokens', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });
    expect(res.status).toBe(200);
    expect(res.body.accessToken).toBeTruthy();
    expect(res.body.refreshToken).toBeTruthy();
  });

  it('4. login with wrong password returns 401', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: 'WrongPass123!' });
    expect(res.status).toBe(401);
  });

  it('5. GET /auth/me with access token returns the user', async () => {
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });
    const res = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${login.body.accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.email).toBe(email);
  });

  it('6. GET /auth/me without token returns 401', async () => {
    const res = await request(app.getHttpServer()).get('/auth/me');
    expect(res.status).toBe(401);
  });

  it('7. refresh returns a new pair and the new access token works on /auth/me', async () => {
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password });
    const refreshed = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: login.body.refreshToken });
    expect(refreshed.status).toBe(200);
    expect(refreshed.body.accessToken).toBeTruthy();
    expect(refreshed.body.refreshToken).not.toBe(login.body.refreshToken);
    const me = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${refreshed.body.accessToken}`);
    expect(me.status).toBe(200);
    expect(me.body.email).toBe(email);
  });

  it('8. refresh with a garbage token returns 401', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: 'garbage-token' });
    expect(res.status).toBe(401);
  });

  it('9. forgot-password returns 202 for a known and an unknown email', async () => {
    const known = await request(app.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email });
    expect(known.status).toBe(202);
    const unknown = await request(app.getHttpServer())
      .post('/auth/forgot-password')
      .send({ email: `nobody-${Date.now()}@test.local` });
    expect(unknown.status).toBe(202);
  });

  it('10. reset-password with a service-minted token returns 200 and the new password logs in', async () => {
    const resetTokens = app.get(ResetTokenService);
    const token = await resetTokens.sign(email);
    const newPassword = 'NewPassword456!';
    const reset = await request(app.getHttpServer())
      .post('/auth/reset-password')
      .send({ token, newPassword });
    expect(reset.status).toBe(200);
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: newPassword });
    expect(login.status).toBe(200);
  });
});