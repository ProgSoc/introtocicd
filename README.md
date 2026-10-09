# introtocicd
Resources for the Progsoc Intro to CI/CD Workshop

A 90-minute, beginner-friendly workshop. You'll learn what CI/CD is and why teams use it, then practise on a real GitHub Actions pipeline: break it on purpose, fix it, and finally make it deploy a live website.

No previous CI/CD experience needed.

## What's here

| | |
|---|---|
| [`workshop/guide.md`](workshop/guide.md) | **Start here.** A step-by-step guide covering the concepts, setup, exercises and deployment |
| [`workshop/solution/ci.yaml`](workshop/solution/ci.yaml) | The finished pipeline, with the deploy job added |
| [`Quests.md`](Quests.md) | More break-it challenges for after the workshop |
| Everything else | **FizzBuzz Terminal**, the example app (see below) |

## What you need

- A GitHub account
- Git
- Node.js 24 LTS
- A code editor

## Agenda

1. What is CI/CD? (10 min)
2. Why bother? (10 min)
3. Anatomy of a pipeline: tasks, gates and transformations (15 min)
4. Our example app and its pipeline (15 min)
5. Hands-on: break the build (25 min)
6. Adding CD: deploy to GitHub Pages (15 min)

---

## The example app: FizzBuzz Terminal

A tiny terminal-style FizzBuzz in the browser, written in TypeScript. Black background, white text. Type a number and press Enter. Enter `0` to quit, then press **Run** to start again.

### Run it

```bash
npm install
```

```bash
npm start
```

It prints the link when it's ready: http://localhost:8000/src/index.html (opening `http://localhost:8000/` redirects there). To use another port, run `PORT=3000 npm start`.

### Scripts

| Command | What it does |
|---|---|
| `npm start` | Build once, then serve on port 8000 |
| `npm run build` | Compile `src/*.ts` to `dist/` |
| `npm run watch` | Recompile whenever a `.ts` file changes |
| `npm run serve` | Serve without building |
| `npm run typecheck` | Type-check `src/` and `tests/` without building |
| `npm run lint` | Lint and format-check with Biome |
| `npm run lint:fix` | Apply Biome's safe fixes |
| `npm test` | Build, then run the Vitest suite |
| `npm run test:watch` | Re-run tests as you edit |
| `npm run ci` | Everything CI runs: typecheck, lint, test |

For live editing, run `npm run watch` and `npm run serve` in two terminal tabs, then refresh the page after each save.

### CI

`.github/workflows/ci.yaml` runs on every push and pull request: `npm ci`, then `typecheck`, `lint`, and `test`, cheapest check first. Run `npm run ci` before pushing to see what GitHub will see.

```
push ─► npm ci ─► typecheck ─► lint ─► test ─► ✅
```

### Layout

```
src/
  index.html     the page
  styles.css     the page's stylesheet (black background, white text)
  404.html       shown for pages that don't exist (its CSS is inline on purpose, see the comment in the file)
  main.ts        terminal behavior: input, output, Run button
  fizzbuzz.ts    the FizzBuzz logic, no browser code
dist/            compiled JavaScript (generated, git-ignored)
tests/           Vitest tests (logic, terminal behavior, dev server)
scripts/
  serve.mjs      dev server: folders serve their index.html, missing pages show src/404.html, only src/ and dist/ are served
workshop/        workshop guide and solution
.github/workflows/ci.yaml   the CI pipeline
biome.json       linter and formatter settings
package.json     scripts and dependencies
tsconfig.json    TypeScript compiler settings (tests/tsconfig.json for type-checking tests)
Quests.md        break-it challenges
```

The page has to be served over http. Opening `index.html` directly as a file won't work, because browsers block module scripts on `file://`.

## Credits

The concepts and the "Topher" story come from chapter 2 of [*Grokking Continuous Delivery*](https://www.manning.com/books/grokking-continuous-delivery) by Christie Wilson (Manning, 2022). The example app was written by Ivan ([local-sailor](https://github.com/local-sailor)) and ported from [local-sailor/ci-cd2_practice](https://github.com/local-sailor/ci-cd2_practice).
