import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Playlists (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let accessToken: string;
  let userId: string;
  let trackId: string;
  let playlistId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get(PrismaService);

    // Register a fresh test user
    const email = `playlist-test-${Date.now()}@example.com`;
    const signupRes = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({
        email,
        password: 'Password123!',
        displayName: 'Playlist Tester',
      });

    accessToken = signupRes.body.accessToken;
    userId = signupRes.body.user.id;

    // Create a track in database for testing
    const track = await prisma.track.create({
      data: {
        title: 'E2E Test Track',
        artist: 'E2E Artist',
        ownerId: userId,
      },
    });
    trackId = track.id;
  });

  afterAll(async () => {
    if (userId) {
      await prisma.user
        .delete({ where: { id: userId } })
        .catch(() => undefined);
    }
    await app.close();
  });

  it('POST /playlists creates a new playlist', async () => {
    const res = await request(app.getHttpServer())
      .post('/playlists')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ name: 'My Test Playlist' })
      .expect(201);

    expect(res.body.id).toBeDefined();
    expect(res.body.name).toBe('My Test Playlist');
    playlistId = res.body.id;
  });

  it('GET /playlists lists user playlists', async () => {
    const res = await request(app.getHttpServer())
      .get('/playlists')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.some((p: { id: string }) => p.id === playlistId)).toBe(
      true,
    );
  });

  it('POST /playlists/:id/tracks adds track to playlist', async () => {
    await request(app.getHttpServer())
      .post(`/playlists/${playlistId}/tracks`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ trackId })
      .expect(201);

    const detailRes = await request(app.getHttpServer())
      .get(`/playlists/${playlistId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(detailRes.body.tracks).toHaveLength(1);
    expect(detailRes.body.tracks[0].id).toBe(trackId);
  });

  it('POST /tracks/:id/like and GET /me/liked-tracks', async () => {
    await request(app.getHttpServer())
      .post(`/tracks/${trackId}/like`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/me/liked-tracks')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(res.body.some((t: { id: string }) => t.id === trackId)).toBe(true);

    await request(app.getHttpServer())
      .delete(`/tracks/${trackId}/like`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
  });

  it('PATCH /playlists/:id renames playlist', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/playlists/${playlistId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ name: 'Renamed Playlist' })
      .expect(200);

    expect(res.body.name).toBe('Renamed Playlist');
  });

  it('DELETE /playlists/:id deletes playlist', async () => {
    await request(app.getHttpServer())
      .delete(`/playlists/${playlistId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .get(`/playlists/${playlistId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);
  });
});
