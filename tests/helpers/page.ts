// Helpers for testing the page (src/index.html + src/main.ts) without a real browser.
// Tests that use these run in Vitest's jsdom environment, a fake browser with a `document`.
// You don't need to understand this file to read the tests. Start with terminal.test.ts.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { vi } from "vitest";

// The prompt main.ts shows before each number.
export const PROMPT = "Enter a number (0 to quit): ";

// Read src/index.html once. (This finds it relative to this file, so it works
// no matter which folder you run the tests from.)
const thisFolder = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(thisFolder, "../../src/index.html"), "utf8");

// Open a fresh copy of the page and start main.ts, like loading it in a browser.
export async function loadPage(): Promise<void> {
  // Put the <body> of index.html on the fake page, without its <script> tag.
  // We start main.ts ourselves just below.
  const page = new DOMParser().parseFromString(html, "text/html");
  for (const script of page.querySelectorAll("script")) script.remove();
  document.body.innerHTML = page.body.innerHTML;

  // main.ts starts running as soon as it's imported. Vitest remembers imports,
  // so we tell it to forget them, otherwise every test would share one old run.
  vi.resetModules();
  await import("../../src/main.js");
}

// Find an element by its id, e.g. element("run") for the Run button.
export function element(id: string): HTMLElement {
  const found = document.getElementById(id);
  if (!found) throw new Error(`No element with id "${id}" on the page`);
  return found;
}

// Type some text into the input and press Enter.
export function enter(text: string): void {
  const input = element("input") as HTMLInputElement;
  input.value = text;
  // Pressing Enter in a form fires its "submit" event, so we fire that directly.
  element("input-line").dispatchEvent(
    new Event("submit", { cancelable: true }),
  );
}

// Click the Run button.
export function clickRun(): void {
  element("run").click();
}

// Every line printed on the screen so far, top to bottom.
export function screenLines(): string[] {
  return Array.from(
    element("screen").children,
    (line) => line.textContent ?? "",
  );
}

// true if the element is hidden, e.g. isHidden("run").
export function isHidden(id: string): boolean {
  // `hidden` can also be the text "until-found" (a newer browser feature),
  // so compare with true instead of returning it as-is.
  return element(id).hidden === true;
}
