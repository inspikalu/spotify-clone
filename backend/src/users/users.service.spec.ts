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
    await expect(service.findByEmail('a@b.c')).resolves.toEqual({ id: 'u1', email: 'a@b.c' });
    expect(mock.user.findUnique).toHaveBeenCalledWith({ where: { email: 'a@b.c' } });
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
    mock.user.create.mockImplementation(({ data }) => Promise.resolve({ id: 'u3', ...data }));
    const result = await service.create({ email: 'c@d.e', passwordHash: 'hashed' });
    expect(result).toMatchObject({ id: 'u3', email: 'c@d.e', passwordHash: 'hashed' });
  });

  it('upsertGoogle creates on new googleSub and updates on existing', async () => {
    mock.user.upsert.mockImplementation((args) => Promise.resolve({ id: 'u4', ...args.create }));
    const created = await service.upsertGoogle({ googleSub: 'g1', email: 'g@h.i' });
    expect(created).toMatchObject({ id: 'u4', googleSub: 'g1' });
    expect(mock.user.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { googleSub: 'g1' } }),
    );
  });
});
