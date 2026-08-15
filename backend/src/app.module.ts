import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { HealthController } from './health/health.controller';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { TracksModule } from './tracks/tracks.module';
import { PlaylistsModule } from './playlists/playlists.module';
import { SearchModule } from './search/search.module';

const REQUIRED_ENV = [
  'DATABASE_URL',
  'JWT_SECRET',
  'ACCESS_TOKEN_TTL',
  'REFRESH_TOKEN_TTL',
  'RESET_TOKEN_TTL',
  'RESEND_API_KEY',
  'RESEND_FROM',
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SUPABASE_AUDIO_BUCKET',
  'SUPABASE_COVERS_BUCKET',
];

function validateEnv(config: Record<string, unknown>): Record<string, unknown> {
  for (const key of REQUIRED_ENV) {
    if (!config[key]) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }
  return config;
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    PrismaModule,
    UsersModule,
    AuthModule,
    TracksModule,
    PlaylistsModule,
    SearchModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
