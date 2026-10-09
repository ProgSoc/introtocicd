import { fizzbuzz } from "./fizzbuzz.js";

const PROMPT = "Enter a number (0 to quit): ";

// Grab an element by id, or fail loudly if index.html is missing it.
function el<T extends HTMLElement>(id: string): T {
  const node = document.getElementById(id);
  if (!node) throw new Error(`Missing element #${id}`);
  return node as T;
}

const terminal = el<HTMLDivElement>("terminal");
const screen = el<HTMLDivElement>("screen");
const form = el<HTMLFormElement>("input-line");
const input = el<HTMLInputElement>("input");
const prompt = el<HTMLSpanElement>("prompt");
const runButton = el<HTMLButtonElement>("run");

let running = false;

// Add one line of output, like print() does.
function print(text: string): void {
  const line = document.createElement("div");
  line.textContent = text;
  screen.appendChild(line);
  terminal.scrollTop = terminal.scrollHeight;
}

// Start (or restart) the script.
function start(): void {
  running = true;
  screen.replaceChildren();
  runButton.hidden = true;
  form.hidden = false;
  prompt.textContent = PROMPT;
  input.value = "";
  input.focus();
}

// The script has exited: hide the input, offer the Run button.
function exit(): void {
  running = false;
  form.hidden = true;
  runButton.hidden = false;
  runButton.focus();
}

// Python's int() would crash on "abc". Here we say so and ask again.
function parseWholeNumber(text: string): number | null {
  if (!/^[+-]?\d+$/.test(text.trim())) return null;
  const n = Number(text);
  return Number.isSafeInteger(n) ? n : null;
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  if (!running) return;

  const raw = input.value;
  input.value = "";
  print(PROMPT + raw); // echo what was typed, like a real terminal

  const n = parseWholeNumber(raw);
  if (n === null) {
    print("Please enter a whole number.");
  } else if (n === 0) {
    print("Goodbye!");
    exit();
  } else {
    print(fizzbuzz(n));
  }
});

runButton.addEventListener("click", start);

// Clicking the black area focuses the input, unless you're selecting text.
terminal.addEventListener("click", () => {
  if (running && !window.getSelection()?.toString()) input.focus();
});

start();
