// Tiny dev server for the terminal page:
//   /          goes to the page
//   a folder   serves that folder's index.html (so /src/ works without typing the file name)
//   anything missing shows src/404.html, with a real 404 status
// It only serves src/ and dist/, and never lists a folder's contents.
import { readFile, stat } from "node:fs/promises";
import { createServer } from "node:http";
import { extname, join, normalize, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = fileURLToPath(new URL("..", import.meta.url));
const PORT = Number(process.env.PORT) || 8000;
const HOME = "/src/index.html";
const INDEX = "index.html";
const NOT_FOUND_PAGE = join(ROOT, "src", "404.html");
const SERVED = ["src", "dist"];

const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".map": "application/json; charset=utf-8",
};

// Send the 404 page. The status is 404 so browsers and tools know the page is missing.
async function notFound(res) {
  let body = "Not found";
  let type = "text/plain";
  try {
    body = await readFile(NOT_FOUND_PAGE);
    type = TYPES[".html"];
  } catch {
    // No 404 page on disk, so fall back to plain text.
  }
  res.writeHead(404, { "Content-Type": type });
  res.end(body);
}

// A folder means "its index.html", like most web servers.
async function resolveFile(path) {
  try {
    return (await stat(path)).isDirectory() ? join(path, INDEX) : path;
  } catch {
    return path; // doesn't exist; readFile will fail and we send the 404 page
  }
}

const server = createServer(async (req, res) => {
  let pathname;
  try {
    pathname = decodeURIComponent(
      new URL(req.url ?? "/", "http://localhost").pathname,
    );
  } catch {
    return notFound(res);
  }

  if (pathname === "/") {
    res.writeHead(302, { Location: HOME });
    return res.end();
  }

  const file = normalize(join(ROOT, pathname));
  const topFolder = file.slice(ROOT.length).split(sep)[0];
  if (!file.startsWith(ROOT) || !SERVED.includes(topFolder))
    return notFound(res);

  try {
    const target = await resolveFile(file);
    const body = await readFile(target); // a folder with no index.html throws here
    res.writeHead(200, {
      "Content-Type": TYPES[extname(target)] ?? "application/octet-stream",
      "Cache-Control": "no-store",
    });
    res.end(body);
  } catch {
    await notFound(res);
  }
});

server.on("error", (err) => {
  console.error(
    err.code === "EADDRINUSE"
      ? `Port ${PORT} is already in use. Stop the other server, or run: PORT=3000 npm start`
      : err.message,
  );
  process.exit(1);
});

server.listen(PORT, "127.0.0.1", () => {
  console.log(`\n  FizzBuzz Terminal: http://localhost:${PORT}${HOME}\n`);
});
