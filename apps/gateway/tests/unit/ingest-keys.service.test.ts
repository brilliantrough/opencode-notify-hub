import { describe, expect, it } from "vitest";

import { sha256Hex } from "../../src/lib/crypto.js";
import type {
  IngestKeyRecord,
  IngestKeyRepository,
} from "../../src/modules/ingest-keys/ingest-keys.repository.js";
import {
  generateIngestKeyId,
  generateIngestKeySecret,
  IngestKeyService,
} from "../../src/modules/ingest-keys/ingest-keys.service.js";

const BASE64URL = /^[A-Za-z0-9_-]+$/;

interface StoredRow extends IngestKeyRecord {
  secretHash: string;
  revoked: boolean;
}

/**
 * In-memory repository that models the real one's semantics: revoked keys
 * vanish from list/findActiveByKeyId, and revoke only matches rows owned by
 * the requesting user.
 */
class FakeIngestKeyRepository implements IngestKeyRepository {
  readonly rows: StoredRow[] = [];
  private nextId = 1;

  async list(userId: string): Promise<IngestKeyRecord[]> {
    return this.rows
      .filter((row) => row.userId === userId && !row.revoked)
      .map(({ secretHash: _secretHash, revoked: _revoked, ...record }) => record);
  }

  async create(input: {
    userId: string;
    keyId: string;
    secretHash: string;
    name: string;
  }): Promise<IngestKeyRecord> {
    const row: StoredRow = {
      id: `key-row-${this.nextId++}`,
      userId: input.userId,
      keyId: input.keyId,
      secretHash: input.secretHash,
      name: input.name,
      createdAt: new Date(),
      lastUsedAt: null,
      revoked: false,
    };
    this.rows.push(row);
    const { secretHash: _secretHash, revoked: _revoked, ...record } = row;
    return record;
  }

  async revoke(input: { userId: string; id: string }): Promise<boolean> {
    const row = this.rows.find(
      (candidate) =>
        candidate.id === input.id && candidate.userId === input.userId && !candidate.revoked,
    );
    if (row === undefined) {
      return false;
    }
    row.revoked = true;
    return true;
  }

  async findActiveByKeyId(keyId: string) {
    const row = this.rows.find((candidate) => candidate.keyId === keyId && !candidate.revoked);
    if (row === undefined) {
      return null;
    }
    return { id: row.id, userId: row.userId, keyId: row.keyId, secretHash: row.secretHash };
  }
}

describe("ingest-key generation", () => {
  it("generates a 12-character base64url key id from 9 random bytes", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 100; i += 1) {
      const keyId = generateIngestKeyId();
      // 9 bytes -> ceil(9/3)*4 = 12 base64url characters, no padding.
      expect(keyId).toHaveLength(12);
      expect(keyId).toMatch(BASE64URL);
      seen.add(keyId);
    }
    expect(seen.size).toBe(100);
  });

  it("generates a 43-character base64url secret from 32 random bytes", () => {
    const seen = new Set<string>();
    for (let i = 0; i < 100; i += 1) {
      const secret = generateIngestKeySecret();
      // 32 bytes -> ceil(32/3)*4 = 44 with padding, 43 unpadded.
      expect(secret).toHaveLength(43);
      expect(secret).toMatch(BASE64URL);
      seen.add(secret);
    }
    expect(seen.size).toBe(100);
  });
});

describe("IngestKeyService.create", () => {
  it("returns the keyId.secret credential once and stores only SHA-256(secret)", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);

    const { record, credential } = await service.create("user-1", "workstation");

    const dot = credential.indexOf(".");
    expect(dot).toBe(12);
    const keyId = credential.slice(0, dot);
    const secret = credential.slice(dot + 1);
    expect(keyId).toMatch(BASE64URL);
    expect(secret).toHaveLength(43);
    expect(secret).toMatch(BASE64URL);

    expect(record.keyId).toBe(keyId);
    expect(record.name).toBe("workstation");
    expect(record.userId).toBe("user-1");

    // The database row holds exactly the SHA-256 of the secret part, never
    // the secret or the full credential.
    const row = repository.rows[0];
    expect(row.secretHash).toBe(sha256Hex(secret));
    expect(row.secretHash).not.toContain(secret);
    expect(JSON.stringify(row)).not.toContain(credential);
  });
});

describe("IngestKeyService.verify", () => {
  it("accepts the credential of an active key and identifies its owner", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);
    const { record, credential } = await service.create("user-1", "workstation");

    const verified = await service.verify(credential);
    expect(verified).toEqual({
      id: record.id,
      userId: "user-1",
      keyId: record.keyId,
    });
  });

  it("rejects a tampered secret", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);
    const { credential } = await service.create("user-1", "workstation");
    const keyId = credential.slice(0, credential.indexOf("."));

    const other = await service.create("user-1", "laptop");
    const wrongSecret = other.credential.slice(other.credential.indexOf(".") + 1);

    expect(await service.verify(`${keyId}.${wrongSecret}`)).toBeNull();
  });

  it("rejects credentials for unknown key ids without throwing", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);
    await service.create("user-1", "workstation");

    expect(await service.verify(`zzzzzzzzzzzz.${generateIngestKeySecret()}`)).toBeNull();
  });

  it("rejects revoked keys", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);
    const { record, credential } = await service.create("user-1", "workstation");

    expect(await repository.revoke({ userId: "user-1", id: record.id })).toBe(true);
    expect(await service.verify(credential)).toBeNull();
  });

  it("rejects malformed credentials", async () => {
    const repository = new FakeIngestKeyRepository();
    const service = new IngestKeyService(repository);
    const { credential } = await service.create("user-1", "workstation");

    for (const malformed of [
      "",
      "no-dot-here",
      ".onlysecret",
      "onlykeyid.",
      `${credential}.extra`,
      "   ",
    ]) {
      expect(await service.verify(malformed)).toBeNull();
    }
  });
});
