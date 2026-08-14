import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { TracksController } from './tracks.controller';
import { TracksService } from './tracks.service';

@Module({
  imports: [StorageModule],
  controllers: [TracksController],
  providers: [TracksService],
})
export class TracksModule {}
