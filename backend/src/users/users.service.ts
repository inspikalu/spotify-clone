import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  create(data: { email: string; passwordHash: string; displayName?: string }) {
    return this.prisma.user.create({
      data: {
        email: data.email,
        passwordHash: data.passwordHash,
        displayName: data.displayName,
      },
    });
  }

  updatePassword(id: string, passwordHash: string) {
    return this.prisma.user.update({ where: { id }, data: { passwordHash } });
  }

  upsertGoogle(data: { googleSub: string; email: string; displayName?: string; avatarUrl?: string }) {
    return this.prisma.user.upsert({
      where: { googleSub: data.googleSub },
      create: {
        googleSub: data.googleSub,
        email: data.email,
        displayName: data.displayName,
        avatarUrl: data.avatarUrl,
      },
      update: {
        email: data.email,
        displayName: data.displayName ?? undefined,
        avatarUrl: data.avatarUrl ?? undefined,
      },
    });
  }
}
