import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { writeFileSync, unlinkSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

function writeWav(path: string): number {
  const sampleRate = 16000;
  const seconds = 1;
  const byteRate = sampleRate * 2;
  const dataSize = seconds * byteRate;
  const buffer = Buffer.alloc(44 + dataSize);
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(1, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(2, 32);
  buffer.writeUInt16LE(16, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);
  writeFileSync(path, buffer);
  return buffer.length;
}

describe('Tracks (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let accessToken: string;
  let audioKey: string | null = null;
  const wavPath = join(tmpdir(), `e2e-track-${Date.now()}.wav`);
  const email = `e2e-tracks-${Date.now()}@test.local`;
  const password = 'Password123!';

  beforeAll(async () => {
    writeWav(wavPath);
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
    prisma = moduleRef.get(PrismaService);
    const signup = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({ email, password, displayName: 'Tracks E2E' });
    accessToken = signup.body.accessToken;
  });

  afterAll(async () => {
    if (audioKey) {
      const base = process.env.SUPABASE_URL ?? '';
      const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? '';
      await fetch(`${base}/storage/v1/object/audio/${audioKey}`, {
        method: 'DELETE',
        headers: { apikey: key, Authorization: `Bearer ${key}` },
      }).catch(() => undefined);
    }
    await prisma.user.deleteMany({
      where: { email: { startsWith: 'e2e-tracks-' } },
    });
    await app.close();
    unlinkSync(wavPath);
  });

  it('1. rejects uploads without a token (401)', async () => {
    const res = await request(app.getHttpServer())
      .post('/tracks')
      .attach('file', wavPath)
      .field('title', 'No Auth')
      .field('artist', 'Nobody');
    expect(res.status).toBe(401);
  });

  it('2. uploads a real WAV and returns a real server-side duration', async () => {
    const res = await request(app.getHttpServer())
      .post('/tracks')
      .set('Authorization', `Bearer ${accessToken}`)
      .attach('file', wavPath, {
        contentType: 'audio/wav',
        filename: 'e2e-test.wav',
      })
      .field('title', 'E2E Song')
      .field('artist', 'E2E Artist')
      .field('album', 'E2E Album');
    if (res.status !== 201)
      console.log('UPLOAD BODY:', JSON.stringify(res.body));
    expect(res.status).toBe(201);
    expect(res.body.title).toBe('E2E Song');
    expect(res.body.artist).toBe('E2E Artist');
    expect(res.body.album).toBe('E2E Album');
    expect(res.body.durationMs).toBeGreaterThanOrEqual(900);
    expect(res.body.durationMs).toBeLessThanOrEqual(1100);
    expect(res.body.audioStorageKey).toBeTruthy();
    expect(res.body.audioUrl).toContain('/object/sign/');
    audioKey = res.body.audioStorageKey;
  });

  it('3. rejects uploads missing a title (400)', async () => {
    const res = await request(app.getHttpServer())
      .post('/tracks')
      .set('Authorization', `Bearer ${accessToken}`)
      .attach('file', wavPath, {
        contentType: 'audio/wav',
        filename: 'e2e-test.wav',
      })
      .field('artist', 'No Title');
    expect(res.status).toBe(400);
    expect(res.body.message).toBe('Title is required');
  });

  it('4. lists the uploaded track with a signed audio URL', async () => {
    const res = await request(app.getHttpServer())
      .get('/tracks')
      .set('Authorization', `Bearer ${accessToken}`);
    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    const uploaded = res.body.find((t: any) => t.title === 'E2E Song');
    expect(uploaded).toBeDefined();
    expect(uploaded.audioUrl).toContain('/object/sign/');
  });
});
