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

  async upsertGoogle(data: {
    googleSub: string;
    email: string;
    displayName?: string;
    avatarUrl?: string;
  }) {
    const bySub = await this.prisma.user.findUnique({
      where: { googleSub: data.googleSub },
    });
    const existing =
      bySub ??
      (await this.prisma.user.findUnique({ where: { email: data.email } }));
    if (existing) {
      return this.prisma.user.update({
        where: { id: existing.id },
        data: {
          googleSub: existing.googleSub ?? data.googleSub,
          email: data.email,
          displayName: data.displayName ?? existing.displayName,
          avatarUrl: data.avatarUrl ?? existing.avatarUrl,
        },
      });
    }
    return this.prisma.user.create({
      data: {
        googleSub: data.googleSub,
        email: data.email,
        displayName: data.displayName,
        avatarUrl: data.avatarUrl,
      },
    });
  }
}
