// Helpers for testing the dev server (scripts/serve.mjs).
// startServer() runs it on a spare port, so it never clashes with `npm start`.
// You don't need to understand this file to read the tests. Start with server.test.ts.
import { type ChildProcess, spawn } from "node:child_process";
import { createServer } from "node:net";
import { fileURLToPath } from "node:url";

const SERVER_SCRIPT = fileURLToPath(
  new URL("../../scripts/serve.mjs", import.meta.url),
);

// What startServer() gives back to a test.
export type TestServer = {
  // The full address for a path, e.g. url("/") → "http://127.0.0.1:51234/"
  url: (path: string) => string;
  // Shut the server down.
  stop: () => void;
};

// Start scripts/serve.mjs and wait until it's ready for requests.
export async function startServer(): Promise<TestServer> {
  const port = await findFreePort();

  // Same as typing `PORT=51234 node scripts/serve.mjs` in a terminal.
  const server = spawn("node", [SERVER_SCRIPT], {
    env: { ...process.env, PORT: String(port) },
  });

  // serve.mjs prints its link once it's listening, so wait for that.
  await waitForOutput(server, `:${port}`);

  return {
    url: (path) => `http://127.0.0.1:${port}${path}`,
    stop: () => server.kill(),
  };
}

// Ask the operating system for a port nobody is using.
function findFreePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const probe = createServer();
    probe.once("error", reject);
    probe.listen(0, "127.0.0.1", () => {
      const { port } = probe.address() as { port: number };
      probe.close(() => resolve(port));
    });
  });
}

// Wait until a running program prints some text (or fail if it quits first).
function waitForOutput(program: ChildProcess, text: string): Promise<void> {
  return new Promise((resolve, reject) => {
    program.stdout?.on("data", (chunk) => {
      if (String(chunk).includes(text)) resolve();
    });
    program.once("error", reject);
    program.once("exit", (code) => {
      reject(
        new Error(`Server stopped before it was ready (exit code ${code})`),
      );
    });
  });
}
