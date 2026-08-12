import { Writable } from "node:stream";

import { describe, expect, it } from "vitest";

import { buildServer } from "../../src/app.js";
import { buildTestConfig } from "../helpers/build-test-app.js";

function captureLogStream(): { stream: Writable; output: () => string } {
  let output = "";
  const stream = new Writable({
    write(chunk, _encoding, callback) {
      output += String(chunk);
      callback();
    },
  });
  return { stream, output: () => output };
}

// Focused smoke test; broader redaction behavior is covered by the integration suite.
describe("central log redaction", () => {
  it("never logs credential or event-content sentinel values", async () => {
    const { stream, output } = captureLogStream();
    const app = await buildServer({
      config: buildTestConfig({ logLevel: "info" }),
      loggerStream: stream,
    });
    // Probe logging a request body and headers the way later modules will.
    app.post("/_probe-log", async (request) => {
      request.log.info({ body: request.body }, "probe body");
      request.log.info({ req: { headers: request.headers } }, "probe headers");
      return { status: "ok" };
    });

    const sentinels = {
      authorization: "SENTINEL-AUTH-01c6e8f2",
      signature: "SENTINEL-SIGN-02d7f903",
      password: "SENTINEL-PASS-03e80a14",
      newPassword: "SENTINEL-NEWP-04f91b25",
      refreshToken: "SENTINEL-REFR-05a02c36",
      token: "SENTINEL-TOKE-06b13d47",
      secret: "SENTINEL-SECR-07c24e58",
      fcmToken: "SENTINEL-FCMT-08d35f69",
      code: "SENTINEL-CODE-13ab09c5",
      questions: "SENTINEL-QUES-09e46070",
      permission: "SENTINEL-PERM-10f57181",
      providerAction: "SENTINEL-PROV-11068292",
      summary: "SENTINEL-SUMM-12179303",
    };

    const res = await app.inject({
      method: "POST",
      url: "/_probe-log",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${sentinels.authorization}`,
        "x-notify-signature": sentinels.signature,
      },
      payload: {
        password: sentinels.password,
        newPassword: sentinels.newPassword,
        refreshToken: sentinels.refreshToken,
        token: sentinels.token,
        secret: sentinels.secret,
        fcmToken: sentinels.fcmToken,
        code: sentinels.code,
        payload: {
          questions: sentinels.questions,
          permission: sentinels.permission,
          providerAction: sentinels.providerAction,
          summary: sentinels.summary,
        },
      },
    });
    expect(res.statusCode).toBe(200);
    await app.close();

    const logged = output();
    // Guard against a vacuous pass: the probe really logged and redaction ran.
    expect(logged).toContain("probe body");
    expect(logged).toContain("probe headers");
    expect(logged).toContain("[redacted]");
    for (const sentinel of Object.values(sentinels)) {
      expect(logged).not.toContain(sentinel);
    }
  });
});
