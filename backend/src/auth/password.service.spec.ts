import { PasswordService } from './password.service';

describe('PasswordService', () => {
  const service = new PasswordService();

  it('hash then verify returns true for the same password', async () => {
    const hash = await service.hash('Password123!');
    await expect(service.verify('Password123!', hash)).resolves.toBe(true);
  });

  it('verify returns false for a wrong password', async () => {
    const hash = await service.hash('Password123!');
    await expect(service.verify('WrongPass!', hash)).resolves.toBe(false);
  });

  it('produces different hashes for the same password (salting)', async () => {
    const h1 = await service.hash('Password123!');
    const h2 = await service.hash('Password123!');
    expect(h1).not.toBe(h2);
  });
});
