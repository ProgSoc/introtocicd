# Intro to CI/CD: workshop guide

Follow along with this guide during the workshop, or work through it on your own afterwards. You don't need any previous experience with CI/CD.

You'll take a small web app, look at the pipeline that checks every change, break that pipeline on purpose a few times, and finally add a step that deploys the app to the internet whenever its checks pass.

The concepts come from chapter 2 of *Grokking Continuous Delivery* by Christie Wilson (Manning, 2022).

**Contents**

0. [Before you start](#0-before-you-start)
1. [The ideas in five minutes](#1-the-ideas-in-five-minutes)
2. [Get the example app running](#2-get-the-example-app-running)
3. [Read the pipeline](#3-read-the-pipeline)
4. [Your first green run](#4-your-first-green-run)
5. [Break the build](#5-break-the-build)
6. [Add CD: deploy to GitHub Pages](#6-add-cd-deploy-to-github-pages)
7. [Where to go next](#7-where-to-go-next)

---

## 0. Before you start

You need:

- A **GitHub account**
- **Git**, set up so you can push to GitHub. Check with `git --version`.
- **Node.js 24 LTS**. Check with `node --version`. Get it from [nodejs.org](https://nodejs.org) if you don't have it.
- A code editor. Any editor works. VS Code is a good default.

---

## 1. The ideas in five minutes

### The problem

Code that works on its own can still break once it's combined with other people's code. Most beginners run into one of these:

- **"Works on my machine."** You forgot to commit a file. Your laptop is fine, but everyone else's build is broken.
- **"Who broke main?"** Ten changes landed today and one of them is bad. Nobody knows which.
- **"Release day panic."** Shipping is a long manual checklist that only one person remembers.

### Continuous integration (CI)

> "The process of combining code changes frequently, with each change verified on check-in."
> (Christie Wilson, *Grokking Continuous Delivery*)

- **Frequently** means small changes, merged often.
- **Verified** means every push runs automated checks, such as linting and tests, and gets a pass or a fail.

### Continuous delivery (CD)

You're doing continuous delivery when both of these are true:

1. **Always shippable:** you could safely release any commit on `main` at any time. CI is what gets you there.
2. **Shipping is easy:** releasing is as simple as pressing a button, because building, publishing and deploying are automated.

| Term | What it means |
|---|---|
| Continuous integration | Every change is merged often and checked automatically |
| Continuous delivery | `main` is always releasable, and a person decides when to ship |
| Continuous deployment | Every change that passes the checks ships automatically |
| CI/CD | The umbrella term for the tools and automation behind all three |

### Tasks and pipelines

- A **task** does one thing, such as linting the code, running the tests or building the app. It's like a function.
- A **pipeline** runs the tasks in the right order and stops as soon as one fails. It's like `main()`.

```python
def pipeline(code):
    lint(code)
    run_tests(code)
    app = build(code)
    url = publish(app)
    deploy(url)
```

### The five basic tasks

| Task | What it does |
|---|---|
| **Lint** | Reads the code and flags mistakes and style problems, without running it |
| **Test** | Runs the code and checks it does what the author meant |
| **Build** | Turns source code into something runnable, such as TypeScript compiled to JavaScript |
| **Publish** | Puts the built thing somewhere other people can get it |
| **Deploy** | Updates the running app to the new version |

### Gates and transformations

This is the key idea from chapter 2.

- **Gates** check the code. Code goes in and a pass or a fail comes out. A fail stops the pipeline. Linting and testing are gates, and together they make up the **CI** part.
- **Transformations** change the code into something else: a built app, a published package, a live website. Building, publishing and deploying are transformations, and they make up the **CD** part.

Gates always come first, so code that hasn't passed every check never gets shipped.

### Why automate it? Topher's story

In the book, Topher's team has a pipeline script, and Topher runs it by hand:

1. **Once a day.** It breaks, but several people changed code yesterday, so he can't tell whose change did it.
2. **On every change**, when teammates tell him they pushed. Someone forgets to tell him.
3. **On git notifications.** The team grows, and running the pipeline becomes his whole job.
4. **With a webhook.** The version control system calls a small server on every push. The server runs the pipeline and emails whoever broke it.

A CI service like GitHub Actions is step 4, ready-made: you write the pipeline and GitHub triggers it.

### The golden rule

> **When the pipeline breaks, stop pushing changes.** Fix it first.

If you push on top of a broken pipeline, the failure gets blamed on you, and the original problem gets harder to untangle. It's even better to run the checks *before* you push.

### Same ideas, different names

| Idea | In GitHub Actions | You may also hear |
|---|---|---|
| Pipeline | Workflow (a YAML file in `.github/workflows/`) | workflow, build |
| Task | Job, made of steps | stage, step, action |
| Trigger | `on: push`, `on: pull_request` | webhook, event |
| Passes | Green tick on the commit | "CI is green" |
| Breaks | Red cross on the commit | "CI is red", "broke the build" |

---

## 2. Get the example app running

The example app is **FizzBuzz Terminal**: a tiny TypeScript web app. You type a number and press Enter:

- divisible by 3 → `Fizz`
- divisible by 5 → `Buzz`
- divisible by both → `FizzBuzz`
- anything else → the number itself
- `0` quits

### 2.1 Fork the repo

1. Open <https://github.com/ProgSoc/introtocicd>.
2. Click **Fork**, then **Create fork**. You now have your own copy at `github.com/<your-username>/introtocicd`.
3. In **your fork**, open the **Actions** tab. GitHub turns workflows off on new forks, so if you see the message *"Workflows aren't being run on this forked repository"*, click **I understand my workflows, go ahead and enable them**.

### 2.2 Clone it and install

Replace `<your-username>` with your GitHub username:

```bash
git clone https://github.com/<your-username>/introtocicd.git
```

```bash
cd introtocicd
```

```bash
npm install
```

### 2.3 Try the app

```bash
npm start
```

Open <http://localhost:8000> and try a few numbers. Press `Ctrl+C` in the terminal to stop the server.

### 2.4 Run the pipeline on your laptop

```bash
npm run ci
```

This runs exactly the checks that GitHub runs: `typecheck`, then `lint`, then `test`. The output should end with something like `Tests  29 passed (29)`. If it does, you're ready.

### What's in the repo

| File | What it does |
|---|---|
| `src/fizzbuzz.ts` | The FizzBuzz logic, with no browser code, so it's easy to test |
| `src/main.ts` | The terminal page: input, output, the Run button |
| `tests/` | The tests, written with [Vitest](https://vitest.dev) |
| `biome.json` | Settings for [Biome](https://biomejs.dev), the linter and formatter |
| `.github/workflows/ci.yaml` | **The pipeline** |
| `Quests.md` | More break-it challenges |
| `workshop/` | This guide, plus the finished pipeline in `workshop/solution/` |

---

## 3. Read the pipeline

Open `.github/workflows/ci.yaml`. It's short:

```yaml
name: CI
on: [push, pull_request]          # the trigger

jobs:
  check:                          # one job (a task)...
    runs-on: ubuntu-24.04         # ...on a brand-new Linux machine
    steps:
      - uses: actions/checkout@v5         # get the code
      - uses: actions/setup-node@v5       # install Node.js
        with:
          node-version: 24
          cache: npm
      - run: npm ci                       # install exact dependency versions
      - run: npm run typecheck            # gate: TypeScript
      - run: npm run lint                 # gate: Biome
      - run: npm test                     # gate: build + Vitest
```

Things to notice:

- **`on: [push, pull_request]`** is the trigger. Every push to any branch, and every pull request, starts the pipeline. This is Topher's webhook, built into GitHub.
- **`runs-on: ubuntu-24.04`** gives you a fresh virtual machine on every run. The only files on it are the ones you committed, which is why CI catches "works on my machine" bugs.
- **`npm ci`** installs the exact versions in `package-lock.json`, so CI tests what you tested.
- **The gates run cheapest first.** Type checking takes a second and the tests take longer, so a typo fails fast. The first failing step stops the run.

The three gates:

| Step | Tool | What it catches |
|---|---|---|
| `npm run typecheck` | TypeScript (`tsc`) | Using the wrong type of value, missing files, typos in names |
| `npm run lint` | Biome | Risky patterns (such as `==`), formatting and import order |
| `npm test` | Vitest | Code that runs but gives the wrong answer |

---

## 4. Your first green run

Make a harmless change so you can watch the pipeline run.

1. Open `README.md` and add a line at the bottom, such as `Forked by <your name> for the CI/CD workshop.`
2. Commit and push:

   ```bash
   git commit -am "Add my name to the README"
   ```

   ```bash
   git push
   ```

3. Open your fork on GitHub and click the **Actions** tab. You'll see a run called "Add my name to the README". Click it, then click the **check** job to watch each step run live.
4. When it finishes, go back to the repo's front page. There's now a green tick next to your latest commit.

That green tick means every gate passed.

---

## 5. Break the build

Now break things on purpose. Do each exercise the same way:

1. **Predict:** before you push, guess which step will go red.
2. **Break:** make the change, then commit and push.
3. **Look:** open the Actions tab, find the red step and read its log.
4. **Fix:** undo the change, then commit and push again until the run is green.

> **Tip:** run `npm run ci` before you push and you'll see the same failure in seconds. That's how you follow the golden rule in real projects. (Exercise 1 is the one case where this *doesn't* save you.)

> **Undo shortcut:** to undo your last commit and push the fix, run `git revert --no-edit HEAD` and then `git push`.

### Exercise 1: "Works on my machine" → red at **typecheck**

This is the most common CI failure in real life: you forget to commit a file.

1. Create a new file, `src/greet.ts`:

   ```ts
   export function greet(): string {
     return "Hello!";
   }
   ```

2. In `src/main.ts`, add this line under the first import:

   ```ts
   import { greet } from "./greet.js";
   ```

   And add this line at the very end of the file:

   ```ts
   console.log(greet());
   ```

3. Run `npm run ci`. **It passes**, because `greet.ts` is on your disk.
4. Now commit **only** `main.ts`:

   ```bash
   git add src/main.ts
   ```

   ```bash
   git status --short
   ```

   You should see `M  src/main.ts` (staged) and `?? src/greet.ts` (not committed). Commit and push:

   ```bash
   git commit -m "Use greet in main"
   ```

   ```bash
   git push
   ```

5. On GitHub, **typecheck** goes red with `error TS2307: Cannot find module './greet.js'`. The CI machine only has the files you committed.
6. Fix it by committing the missing file:

   ```bash
   git add src/greet.ts
   ```

   ```bash
   git commit -m "Add greet.ts"
   ```

   ```bash
   git push
   ```

### Exercise 2: A risky pattern → red at **lint**

In `src/fizzbuzz.ts`, change

```ts
} else if (n % 3 === 0) {
```

to

```ts
} else if (n % 3 == 0) {
```

Commit and push. The app still works, but Biome flags it:

```
lint/suspicious/noDoubleEquals
× Using == may be unsafe if you are relying on type coercion.
i Unsafe fix: Use === instead.
```

In JavaScript, `==` quietly converts types before comparing (`"0" == 0` is `true`), which causes bugs that are hard to spot. The team's lint rules forbid it, so the pipeline stops **before the tests even run**.

Undo the change and push again.

> **Bonus:** add some messy spacing to any `.ts` file and run `npm run lint`. Biome checks formatting too. Then run `npm run lint:fix` to have Biome tidy it up for you.

### Exercise 3: The wrong type → red at **typecheck**

In `src/fizzbuzz.ts`, change

```ts
return String(n);
```

to

```ts
return n;
```

Commit and push. TypeScript refuses:

```
src/fizzbuzz.ts(10,5): error TS2322: Type 'number' is not assignable to type 'string'.
```

The function promises to return a `string` (`fizzbuzz(n: number): string`) but now returns a number. TypeScript catches this without running any code. Plain JavaScript would only find out when the app ran.

Undo the change and push again.

### Exercise 4: Wrong maths → red at **test**

In `src/fizzbuzz.ts`, change

```ts
if (n % 15 === 0) {
```

to

```ts
if (n % 14 === 0) {
```

Commit and push. This is valid code, so typecheck and lint both pass. Only a test that knows the right answer can catch it:

```
× fizzbuzz(15) is FizzBuzz
× fizzbuzz(30) is FizzBuzz
× fizzbuzz(45) is FizzBuzz
Expected: "FizzBuzz"
Received: "Fizz"
```

Open `tests/fizzbuzz.test.ts` to see how the tests work. Each row in the table is one test: call `fizzbuzz` with this number and expect this answer.

```ts
it.each([
  [3, "Fizz"],
  [5, "Buzz"],
  [15, "FizzBuzz"],
  // ...
])("fizzbuzz(%i) is %s", (n, expected) => {
  expect(fizzbuzz(n)).toBe(expected);
});
```

Undo the change and push again.

> **Bonus:** add your own row to the table, such as `[60, "FizzBuzz"]`, and run `npm test`. Then add a row with a *wrong* answer and watch it fail.

### Exercise 5: Is this test too strict? → red at **test**

In `src/main.ts`, change the message

```ts
print("Please enter a whole number.");
```

to

```ts
print("Nope.");
```

Commit and push. The test "rejects bad input and keeps going" fails, and Vitest shows the difference (`-` is what the test expected, `+` is what it got):

```
  [
    "Enter a number (0 to quit): abc",
-   "Please enter a whole number.",
+   "Nope.",
  ]
```

Nothing is broken for the user, because only the wording changed. **Discuss:** is that a good test or a bad one? Tests that check exact text catch accidental changes, but they also fail on harmless edits. Real teams make this trade-off all the time.

Undo the change and push again.

### Fast finisher: see the checks on a pull request

1. Create a branch: `git switch -c try-a-pr`
2. Make one of the breaking changes above, then commit and `git push -u origin try-a-pr`.
3. On GitHub, open a pull request **into your own fork's `main`**. (By default GitHub points it at the original repo, so change the "base repository" dropdown.)
4. The checks run on the pull request, and GitHub shows a red cross before anyone merges. This is how teams keep `main` green.

Want more? `Quests.md` in the repo has ten challenges, including ones that break the dev server and the page.

---

## 6. Add CD: deploy to GitHub Pages

So far the pipeline only has gates. It tells you whether the code is good, but it doesn't deliver anything. Now you'll add the transformations: **build → publish → deploy**, so every green push to `main` updates a live website.

```
git push to main ─► check job ─► deploy job ─► https://<you>.github.io/introtocicd/
                    typecheck     build
                    lint          upload (publish)
                    test          deploy
```

### 6.1 One-time setup

In **your fork** on GitHub, go to **Settings → Pages**. Under **Build and deployment → Source**, choose **GitHub Actions**.

### 6.2 Add the deploy job

Open `.github/workflows/ci.yaml` and add this `deploy` job **below** the `check` job, at the same indentation as `check:`. (The complete file is in [`solution/ci.yaml`](solution/ci.yaml) if you get stuck.)

```yaml
  deploy:
    # Only start once every gate in `check` has passed.
    needs: check
    # Pull requests get checked but never shipped. Only pushes to main deploy.
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-24.04

    # Just enough access to publish to GitHub Pages, nothing more.
    permissions:
      contents: read
      pages: write
      id-token: write

    # Shows the live link on the run's summary page.
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - uses: actions/checkout@v5

      - uses: actions/setup-node@v5
        with:
          node-version: 24
          cache: npm

      - run: npm ci

      # Build: compile src/*.ts to dist/*.js
      - run: npm run build

      # The page at src/index.html loads ../dist/main.js, so keep both folders
      # side by side, and send visitors at the site root to the page.
      - name: Assemble the site
        run: |
          mkdir _site
          cp -r src dist _site/
          echo '<meta http-equiv="refresh" content="0; url=src/">' > _site/index.html

      # Publish: package the site as a Pages artifact
      - uses: actions/upload-pages-artifact@v5
        with:
          path: _site

      # Deploy: make that artifact the live site
      - id: deployment
        uses: actions/deploy-pages@v5
```

What the important lines do:

| Line | Why it's there |
|---|---|
| `needs: check` | **Gates first.** Deploy waits for `check` and is skipped if it fails |
| `if: ... refs/heads/main` | Only pushes to `main` deploy. Pull requests and other branches are checked but not shipped |
| `permissions:` | Lets this job publish to Pages, and nothing else |
| `npm run build` | **Build** (transformation): TypeScript becomes JavaScript |
| `upload-pages-artifact` | **Publish** (transformation): packages the files where Pages can get them |
| `deploy-pages` | **Deploy** (transformation): makes them the live site |

### 6.3 Ship it

```bash
git commit -am "Deploy to GitHub Pages"
```

```bash
git push
```

In the Actions tab, the run now has two jobs: **check**, then **deploy**. When deploy finishes, click it. The live URL appears under the job name, and on the run's summary page. Open it, and your app is on the internet.

Because every green push to `main` now goes live automatically, you're doing **continuous deployment**.

### 6.4 Prove the gates protect you

Repeat Exercise 4 (change `n % 15` to `n % 14`) and push.

- **check** goes red.
- **deploy** is **skipped**.
- The live site still shows the last good version.

This is the whole point: broken code never gets shipped. Undo the change, push, and watch it deploy again.

---

## 7. Where to go next

**Recap**

1. **CI:** merge small changes often, and verify every one automatically.
2. **CD:** `main` is always shippable, and shipping takes one button.
3. **Gates first:** lint and test, then build, publish and deploy.
4. **Automate the trigger:** every push runs the pipeline, so nobody has to be Topher.
5. **Red means stop:** fix the pipeline before pushing more. Run the checks locally first.

**Try this week:** add a workflow to one of your own projects, even if it only runs a linter. A green tick on your GitHub projects looks good to employers, too.

**Read more**

- *Grokking Continuous Delivery*, Christie Wilson (Manning, 2022). Today was chapter 2. Chapters 4 to 6 go deep on linting and testing.
- [GitHub Actions documentation](https://docs.github.com/actions)
- [Biome](https://biomejs.dev) and [Vitest](https://vitest.dev), the linter and test runner used today
- `Quests.md` in this repo, for more break-it challenges

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Nothing appears in the Actions tab after you push | Workflows are off on new forks. Open the Actions tab and click **I understand my workflows, go ahead and enable them**, then push again |
| `npm install` warns about an unsupported engine | Install Node.js 24 LTS from [nodejs.org](https://nodejs.org) |
| `git push` asks for a password and then fails | GitHub doesn't accept account passwords over HTTPS. Sign in with [GitHub CLI](https://cli.github.com) (`gh auth login`) or set up an SSH key |
| Lint fails on a file you didn't mean to change | Your editor reformatted it. Run `npm run lint:fix`, then commit |
| Port 8000 is already in use | Stop the other server, or on macOS/Linux run `PORT=3000 npm start` |
| The deploy job fails with "Get Pages site failed" or a 404 | Pages isn't switched on yet. Set **Settings → Pages → Source** to **GitHub Actions**, then re-run the job |
| The deploy job says the branch "is not allowed to deploy to github-pages" | You pushed from a branch other than `main`. Only `main` can deploy |
| The live site is blank | Open `/src/` on your site. If the page shows but doesn't respond to typing, check that the "Assemble the site" step copied both `src` and `dist` |
