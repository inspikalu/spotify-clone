import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('SearchController (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let accessToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);

    // Register test user
    const email = `search-e2e-${Date.now()}@example.com`;
    const signupRes = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({
        email,
        password: 'Password123!',
        displayName: 'Search Tester',
      });
    accessToken = signupRes.body.accessToken;

    // Seed a test track for search
    const user = await prisma.user.findUnique({ where: { email } });
    await prisma.track.create({
      data: {
        title: 'Searchable E2E Song',
        artist: 'Search Artist',
        album: 'Search Album',
        durationMs: 180000,
        audioStorageKey: 'tracks/test.mp3',
        ownerId: user!.id,
      },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('rejects unauthenticated search requests with 401', () => {
    return request(app.getHttpServer()).get('/search?q=test').expect(401);
  });

  it('returns empty results array when query is empty', () => {
    return request(app.getHttpServer())
      .get('/search?q=')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body.tracks).toEqual([]);
        expect(res.body.playlists).toEqual([]);
      });
  });

  it('searches tracks and playlists successfully with matches', () => {
    return request(app.getHttpServer())
      .get('/search?q=Searchable')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect((res) => {
        expect(res.body.tracks.length).toBeGreaterThanOrEqual(1);
        expect(res.body.tracks[0].title).toBe('Searchable E2E Song');
      });
  });
});
