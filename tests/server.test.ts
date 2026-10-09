// Checks the dev server in scripts/serve.mjs.
// Each test asks the server for one address and checks the answer it gets.
// startServer() (in ./helpers/server.ts) runs a private copy on a spare port.
//
// `npm test` builds first, so dist/main.js exists for the third test.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { startServer, type TestServer } from "./helpers/server.js";

let server: TestServer;

// Start the server once before all the tests, and stop it after them.
beforeAll(async () => {
  server = await startServer();
});

afterAll(() => {
  server.stop();
});

describe("dev server", () => {
  it("redirects / to the page", async () => {
    // redirect: "manual" means: don't follow the redirect, show it to us
    const res = await fetch(server.url("/"), { redirect: "manual" });

    expect(res.status).toBe(302); // 302 = "it's over there"
    expect(res.headers.get("location")).toBe("/src/index.html");
  });

  it("serves the page", async () => {
    const res = await fetch(server.url("/src/index.html"));

    expect(res.status).toBe(200); // 200 = OK
    expect(await res.text()).toContain("FizzBuzz Terminal");
  });

  it("serves a folder's index.html", async () => {
    // Asking for a folder (/src/) should give its index.html, like most web servers.
    const res = await fetch(server.url("/src/"));

    expect(res.status).toBe(200);
    expect(await res.text()).toContain("FizzBuzz Terminal");
  });

  it("serves the compiled script", async () => {
    // If this fails, the page loads but stays blank.
    const res = await fetch(server.url("/dist/main.js"));

    expect(res.status).toBe(200);
  });

  it("returns a 404 status for an unknown path", async () => {
    const res = await fetch(server.url("/nope"));

    expect(res.status).toBe(404); // 404 = not found
  });

  it("shows the 404 page for an unknown path", async () => {
    // The status says "missing". The page tells the visitor.
    const res = await fetch(server.url("/nope"));

    expect(await res.text()).toContain("Page not found");
  });

  it("returns 404 for a folder with no index.html (no file listing)", async () => {
    // dist/ has no index.html, so there is nothing to show.
    const res = await fetch(server.url("/dist/"));

    expect(res.status).toBe(404);
  });
});
