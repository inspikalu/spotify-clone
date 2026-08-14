import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Google auth (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. POST /auth/google with a missing idToken returns 400', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/google')
      .send({});
    expect(res.status).toBe(400);
  });

  it('2. POST /auth/google with a malformed idToken returns 401', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/google')
      .send({ idToken: 'not-a-real-google-token' });
    expect(res.status).toBe(401);
  });
});
