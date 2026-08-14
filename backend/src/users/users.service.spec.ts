import { Test } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';

function prismaMock() {
  return {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      upsert: jest.fn(),
    },
  };
}

describe('UsersService', () => {
  let service: UsersService;
  const mock = prismaMock();

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [UsersService, { provide: PrismaService, useValue: mock }],
    }).compile();
    service = module.get(UsersService);
  });

  it('findByEmail returns the user on hit', async () => {
    mock.user.findUnique.mockResolvedValue({ id: 'u1', email: 'a@b.c' });
    await expect(service.findByEmail('a@b.c')).resolves.toEqual({
      id: 'u1',
      email: 'a@b.c',
    });
    expect(mock.user.findUnique).toHaveBeenCalledWith({
      where: { email: 'a@b.c' },
    });
  });

  it('findByEmail returns null on miss', async () => {
    mock.user.findUnique.mockResolvedValue(null);
    await expect(service.findByEmail('nope@b.c')).resolves.toBeNull();
  });

  it('findById returns the user', async () => {
    mock.user.findUnique.mockResolvedValue({ id: 'u2' });
    await expect(service.findById('u2')).resolves.toEqual({ id: 'u2' });
  });

  it('create stores the password hash', async () => {
    mock.user.create.mockImplementation(({ data }) =>
      Promise.resolve({ id: 'u3', ...data }),
    );
    const result = await service.create({
      email: 'c@d.e',
      passwordHash: 'hashed',
    });
    expect(result).toMatchObject({
      id: 'u3',
      email: 'c@d.e',
      passwordHash: 'hashed',
    });
  });

  it('upsertGoogle creates a new user when no googleSub or email match exists', async () => {
    mock.user.findUnique.mockResolvedValue(null);
    mock.user.create.mockImplementation(({ data }) =>
      Promise.resolve({ id: 'u4', ...data }),
    );
    const created = await service.upsertGoogle({
      googleSub: 'g1',
      email: 'g@h.i',
      displayName: 'G',
    });
    expect(mock.user.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { googleSub: 'g1', email: 'g@h.i', displayName: 'G' },
      }),
    );
    expect(created).toMatchObject({ id: 'u4', googleSub: 'g1' });
  });

  it('upsertGoogle matches by googleSub first, then by email, and links googleSub onto an existing email user', async () => {
    mock.user.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce({
      id: 'u5',
      email: 'g@h.i',
      googleSub: null,
      displayName: 'Old',
      avatarUrl: null,
    });
    mock.user.update.mockImplementation(({ data }) =>
      Promise.resolve({ id: 'u5', ...data }),
    );
    const linked = await service.upsertGoogle({
      googleSub: 'g1',
      email: 'g@h.i',
      avatarUrl: 'pic',
    });
    expect(mock.user.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'u5' },
        data: expect.objectContaining({ googleSub: 'g1', avatarUrl: 'pic' }),
      }),
    );
    expect(linked).toMatchObject({ googleSub: 'g1' });

    jest.clearAllMocks();
    mock.user.findUnique.mockResolvedValue({ id: 'u6', googleSub: 'g1' });
    mock.user.update.mockImplementation(({ data }) =>
      Promise.resolve({ id: 'u6', ...data }),
    );
    const bySub = await service.upsertGoogle({
      googleSub: 'g1',
      email: 'other@h.i',
    });
    expect(bySub).toMatchObject({ id: 'u6' });
    expect(mock.user.findUnique).toHaveBeenNthCalledWith(1, {
      where: { googleSub: 'g1' },
    });
  });
});
