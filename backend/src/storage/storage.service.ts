import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Readable } from 'stream';

@Injectable()
export class StorageService {
  private readonly baseUrl: string;
  private readonly serviceRoleKey: string;

  constructor(config: ConfigService) {
    this.baseUrl = config.get<string>('SUPABASE_URL') ?? '';
    this.serviceRoleKey = config.get<string>('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  }

  private storageUrl(path: string): string {
    return `${this.baseUrl}/storage/v1${path}`;
  }

  private async request(
    method: string,
    path: string,
    init: { headers?: Record<string, string>; body?: BodyInit } = {},
  ): Promise<unknown> {
    const fetchInit: RequestInit & { duplex: 'half' } = {
      method,
      headers: {
        apikey: this.serviceRoleKey,
        Authorization: `Bearer ${this.serviceRoleKey}`,
        ...init.headers,
      },
      body: init.body,
      duplex: 'half',
    };
    const res = await fetch(this.storageUrl(path), fetchInit);
    if (!res.ok) {
      const text = await res.text().catch(() => '');
      throw new InternalServerErrorException(
        `Storage request failed: ${method} ${path} (${res.status}) ${text}`.trim(),
      );
    }
    return res.json();
  }

  async uploadObject(
    bucket: string,
    key: string,
    stream: Readable,
    contentType: string,
  ): Promise<void> {
    await this.request('POST', `/object/${bucket}/${key}`, {
      headers: { 'Content-Type': contentType, 'x-upsert': 'true' },
      body: Readable.toWeb(stream) as unknown as BodyInit,
    });
  }

  async createSignedUrl(
    bucket: string,
    key: string,
    expiresInSeconds = 3600,
  ): Promise<string> {
    const body = (await this.request('POST', `/object/sign/${bucket}/${key}`, {
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ expiresIn: expiresInSeconds }),
    })) as { signedURL: string };
    return `${this.baseUrl}/storage/v1${body.signedURL}`;
  }

  publicUrl(bucket: string, key: string): string {
    return `${this.baseUrl}/storage/v1/object/public/${bucket}/${key}`;
  }

  async deleteObject(bucket: string, key: string): Promise<void> {
    await this.request('DELETE', `/object/${bucket}/${key}`);
  }
}
