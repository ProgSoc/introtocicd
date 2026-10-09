// @vitest-environment jsdom
//
// Checks the terminal page: src/index.html + src/main.ts.
// The line above gives these tests a fake browser (jsdom), so there's a page to test.
// Each test follows the same pattern: type something, then check the screen.
// The setup lives in ./helpers/page.ts.
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  clickRun,
  element,
  enter,
  isHidden,
  loadPage,
  PROMPT,
  screenLines,
} from "./helpers/page.js";

// Every test starts with a freshly loaded page.
beforeEach(async () => {
  await loadPage();
});

// Undo any spies a test set up (see "loads without errors").
afterEach(() => {
  vi.restoreAllMocks();
});

describe("terminal", () => {
  it("loads without errors", async () => {
    // A spy watches console.error so we can check nobody called it.
    const consoleErrors = vi.spyOn(console, "error");
    await loadPage();
    expect(consoleErrors).not.toHaveBeenCalled();
  });

  it("starts with a prompt, an empty screen and no Run button", () => {
    expect(element("prompt").textContent).toBe(PROMPT);
    expect(screenLines()).toEqual([]);
    expect(isHidden("input-line")).toBe(false);
    expect(isHidden("run")).toBe(true);
  });

  it("echoes what you typed, then prints the result", () => {
    enter("3");
    enter("5");
    enter("15");
    enter("7");

    expect(screenLines()).toEqual([
      `${PROMPT}3`,
      "Fizz",
      `${PROMPT}5`,
      "Buzz",
      `${PROMPT}15`,
      "FizzBuzz",
      `${PROMPT}7`,
      "7",
    ]);
  });

  it("0 quits: says Goodbye, hides the input, shows the Run button", () => {
    enter("0");

    expect(screenLines()).toEqual([`${PROMPT}0`, "Goodbye!"]);
    expect(isHidden("input-line")).toBe(true);
    expect(isHidden("run")).toBe(false);
  });

  it("ignores input after quitting", () => {
    enter("0");
    const before = screenLines();

    enter("3");

    expect(screenLines()).toEqual(before);
  });

  it("Run restarts with a clean screen", () => {
    enter("3");
    enter("0");

    clickRun();

    expect(screenLines()).toEqual([]);
    expect(isHidden("input-line")).toBe(false);
    expect(isHidden("run")).toBe(true);

    enter("5");
    expect(screenLines()).toEqual([`${PROMPT}5`, "Buzz"]);
  });

  it("rejects bad input and keeps going", () => {
    enter("abc");

    expect(screenLines()).toEqual([
      `${PROMPT}abc`,
      "Please enter a whole number.",
    ]);
    expect(isHidden("input-line")).toBe(false);

    enter("9");
    expect(screenLines().at(-1)).toBe("Fizz");
  });
});
