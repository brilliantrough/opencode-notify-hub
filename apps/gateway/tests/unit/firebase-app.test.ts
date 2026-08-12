import { generateKeyPairSync } from "node:crypto";

import { getApps, deleteApp } from "firebase-admin/app";
import { afterEach, describe, expect, it } from "vitest";

import {
  InvalidServiceAccountError,
  messagingFromServiceAccountJson,
} from "../../src/modules/fcm/firebase-app.js";

let counter = 0;
const createdApps: string[] = [];

/** Throwaway real PEM: firebase-admin's `cert()` parses the key eagerly. */
const PRIVATE_KEY = generateKeyPairSync("rsa", { modulusLength: 2048 })
  .privateKey.export({ type: "pkcs8", format: "pem" })
  .toString();

function serviceAccount(projectId: string): string {
  return JSON.stringify({
    project_id: projectId,
    client_email: `firebase-adminsdk@${projectId}.iam.gserviceaccount.com`,
    private_key: PRIVATE_KEY,
  });
}

/** Unique project per test: firebase apps are process-global state. */
function uniqueProject(): string {
  counter += 1;
  return `notify-unit-${process.pid}-${counter}`;
}

afterEach(async () => {
  for (const name of createdApps.splice(0)) {
    const app = getApps().find((candidate) => candidate.name === name);
    if (app !== undefined) {
      await deleteApp(app);
    }
  }
});

describe("messagingFromServiceAccountJson", () => {
  it("initializes a named app from validated service account JSON", () => {
    const project = uniqueProject();
    const messaging = messagingFromServiceAccountJson(serviceAccount(project));
    expect(messaging).toBeDefined();
    createdApps.push(`notify-fcm-${project}`);
    expect(getApps().some((app) => app.name === `notify-fcm-${project}`)).toBe(true);
  });

  it("reuses the named app: two creations for one project do not duplicate-initialize", () => {
    const project = uniqueProject();
    createdApps.push(`notify-fcm-${project}`);
    const first = messagingFromServiceAccountJson(serviceAccount(project));
    const second = messagingFromServiceAccountJson(serviceAccount(project));
    expect(first).toBeDefined();
    expect(second).toBeDefined();
    const matching = getApps().filter((app) => app.name === `notify-fcm-${project}`);
    expect(matching).toHaveLength(1);
  });

  it("different projects get independent named apps", () => {
    const projectA = uniqueProject();
    const projectB = uniqueProject();
    createdApps.push(`notify-fcm-${projectA}`, `notify-fcm-${projectB}`);
    messagingFromServiceAccountJson(serviceAccount(projectA));
    messagingFromServiceAccountJson(serviceAccount(projectB));
    expect(getApps().some((app) => app.name === `notify-fcm-${projectA}`)).toBe(true);
    expect(getApps().some((app) => app.name === `notify-fcm-${projectB}`)).toBe(true);
  });

  it("rejects malformed JSON without initializing anything", () => {
    const before = getApps().length;
    expect(() => messagingFromServiceAccountJson("not json")).toThrow(
      InvalidServiceAccountError,
    );
    expect(getApps()).toHaveLength(before);
  });

  it("rejects a service account missing required fields", () => {
    const before = getApps().length;
    expect(() =>
      messagingFromServiceAccountJson(JSON.stringify({ project_id: "x" })),
    ).toThrow(InvalidServiceAccountError);
    expect(getApps()).toHaveLength(before);
  });
});
