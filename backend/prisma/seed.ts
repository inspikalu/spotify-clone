import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';
import { parseFile } from 'music-metadata';

const prisma = new PrismaClient();

const SUPABASE_URL = process.env.SUPABASE_URL || 'http://127.0.0.1:54323';
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
const AUDIO_BUCKET = process.env.SUPABASE_AUDIO_BUCKET || 'audio';
const COVERS_BUCKET = process.env.SUPABASE_COVERS_BUCKET || 'covers';

const SONGS_DIR = '/home/inspiuser/Downloads/spotify-clone/songs';
const COVERS_DIR = '/home/inspiuser/Downloads/spotify-clone/cover art';

const TRACKS_METADATA = [
  {
    audioFile: 'Famous-Pluto-Praise-and-Worship-feat-Brazy.mp3',
    coverFile: 'street-therapist-cover-art.jpg',
    title: 'Praise and Worship',
    artist: 'Famous Pluto, Brazy',
    album: 'STREET THERAPIST',
  },
  {
    audioFile: 'Rema-TEA.mp3',
    coverFile: 'rema-tea.jpg',
    title: 'TEA',
    artist: 'Rema',
    album: null,
  },
  {
    audioFile: 'Seyi-Vibez-ALBERT-EINSTEIN.mp3',
    coverFile: 'lo seyi professor cover art.jpg',
    title: 'ALBERT EINSTEIN',
    artist: 'Seyi Vibez',
    album: 'Loseyi Professor',
  },
  {
    audioFile: 'Seyi-Vibez-Apala-Interlude.mp3',
    coverFile: 'Apala Interlude cover art.jpg',
    title: 'Apala Interlude',
    artist: 'Seyi Vibez',
    album: 'NAHAMciaga',
  },
  {
    audioFile: 'Seyi-Vibez-Love-is-war-ft-Yxng-Ka.mp3',
    coverFile: 'Love Is War cover art.jpg',
    title: 'Love Is War',
    artist: 'Seyi Vibez, Yxng K.A',
    album: null,
  },
  {
    audioFile: 'Seyi-Vibez-Suddenly-feat-Young-John.mp3',
    coverFile: 'Suddenly cover art.jpg',
    title: 'Suddenly',
    artist: 'Seyi Vibez, Young Jonn',
    album: 'Vibe Till Thy Kingdom Come',
  },
];

async function uploadToStorage(bucket: string, objectKey: string, filePath: string, contentType: string) {
  const fileBuffer = fs.readFileSync(filePath);
  const url = `${SUPABASE_URL}/storage/v1/object/${bucket}/${objectKey}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${SERVICE_KEY}`,
      'Content-Type': contentType,
      'x-upsert': 'true',
    },
    body: fileBuffer,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Failed to upload ${objectKey} to ${bucket}: ${response.status} ${errorText}`);
  }
}

async function main() {
  console.log('Seeding tracks to database and Supabase storage...');

  // 1. Get or create a default catalog system user
  let user = await prisma.user.findFirst();
  if (!user) {
    user = await prisma.user.create({
      data: {
        email: 'catalog@spotify.local',
        displayName: 'Spotify Catalog',
      },
    });
  }

  // Also attach tracks to all registered users so everyone sees the catalog
  const allUsers = await prisma.user.findMany();

  for (const meta of TRACKS_METADATA) {
    const audioPath = path.join(SONGS_DIR, meta.audioFile);
    const coverPath = path.join(COVERS_DIR, meta.coverFile);

    if (!fs.existsSync(audioPath)) {
      console.warn(`Audio file missing: ${audioPath}`);
      continue;
    }

    let durationMs: number | null = null;
    try {
      const parsed = await parseFile(audioPath);
      durationMs = parsed.format.duration ? Math.round(parsed.format.duration * 1000) : null;
    } catch (e) {
      console.warn(`Could not parse duration for ${audioPath}:`, e);
    }

    // Process for each user so owner-scoped queries return all catalog songs
    for (const u of allUsers) {
      // Check if already seeded
      const existing = await prisma.track.findFirst({
        where: {
          title: meta.title,
          artist: meta.artist,
          ownerId: u.id,
        },
      });

      const trackId = existing ? existing.id : (await prisma.track.create({
        data: {
          title: meta.title,
          artist: meta.artist,
          album: meta.album,
          durationMs,
          ownerId: u.id,
        },
      })).id;

      const audioKey = `audio/${trackId}.mp3`;
      await uploadToStorage(AUDIO_BUCKET, audioKey, audioPath, 'audio/mpeg');

      let coverUrl: string | null = null;
      if (fs.existsSync(coverPath)) {
        const coverExt = path.extname(meta.coverFile).replace('.', '') || 'jpeg';
        const coverKey = `covers/${trackId}.${coverExt}`;
        await uploadToStorage(COVERS_BUCKET, coverKey, coverPath, `image/${coverExt === 'jpg' ? 'jpeg' : coverExt}`);
        coverUrl = `${SUPABASE_URL}/storage/v1/object/public/${COVERS_BUCKET}/${coverKey}`;
      }

      await prisma.track.update({
        where: { id: trackId },
        data: {
          audioStorageKey: audioKey,
          coverUrl,
        },
      });

      console.log(`✓ Seeded "${meta.title}" by ${meta.artist} (User: ${u.email})`);
    }
  }

  console.log('Seeding complete!');
}

main()
  .catch((e) => {
    console.error('Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
