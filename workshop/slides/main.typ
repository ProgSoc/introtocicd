// Intro to CI/CD: the workshop slides.
// Theme: gh-minimal-slides (https://typst.app/universe/package/gh-minimal-slides)
//
// Build:  typst compile workshop/slides/main.typ
// Watch:  typst watch workshop/slides/main.typ
//
// Colour code used throughout: the accent (blue) means a gate, which checks
// code (CI). Amber ("warning") means a transformation, which delivers code (CD).

#import "@preview/touying:0.7.3": *
#import "@preview/gh-minimal-slides:0.1.0" as gh

#show: gh.register.with(
  theme: "dark",
  accent: "blue",
  density: "compact",
  title: "intro-to-cicd",
)

// JetBrains Mono's code ligatures draw `==` and `===` as single glyphs,
// which hides the exact difference the lint slides are about.
#set text(ligatures: false, features: (calt: 0))

// ---------- small helpers built on the theme's live palette ----------

// Text in the gate colour (accent) or the transformation colour (amber).
#let gate(body) = context text(fill: gh._gh-state.get().accent, weight: 600, body)
#let transform(body) = context text(fill: gh._gh-state.get().palette.warning, weight: 600, body)
#let muted(body) = context text(fill: gh._gh-state.get().palette.fg-muted, body)

// A small label above a code panel.
#let label(body) = context {
  let ctx = gh._gh-state.get()
  text(font: "JetBrains Mono", size: ctx.ts.micro, fill: ctx.palette.fg-muted, body)
}

// A row of pills joined by arrows, e.g. a pipeline.
#let flow(..steps) = context {
  let ctx = gh._gh-state.get()
  let pill((body, kind)) = box(
    fill: ctx.palette.bg-neutral-muted,
    stroke: 1pt + if kind == "gate" { ctx.accent } else if kind == "transform" { ctx.palette.warning } else { ctx.palette.border-default },
    inset: (x: 12pt, y: 6pt),
    radius: 999pt,
    text(font: "JetBrains Mono", size: ctx.ts.small, fill: ctx.palette.fg-default, body),
  )
  steps.pos().map(pill).join(text(fill: ctx.palette.fg-subtle)[#h(8pt)→#h(8pt)])
}

// =====================================================================
// Welcome
// =====================================================================

#gh.cover-slide(
  kicker: "# progsoc / intro-to-cicd",
  title: [Intro to CI/CD],
  badges: (
    "workshop",
    ("lint → test → build → deploy", "accent"),
    ("build: passing", "success"),
    "90 min",
  ),
  footer-left: "Progsoc · 2026",
  footer-right: "github.com/ProgSoc/introtocicd",
)

#gh.task-slide(
  title: [What you'll need today],
  tasks: (
    (false, [A GitHub account], "github.com/signup"),
    (false, [Git, set up so you can push to GitHub], "git --version"),
    (false, [Node.js 24 LTS], "node --version"),
    (false, [A text editor (VS Code is a good default)], "code.visualstudio.com"),
    (false, [Your own fork of the workshop repo], "github.com/ProgSoc/introtocicd"),
  ),
)

// =====================================================================
// What is CI/CD
// =====================================================================

#gh.section-slide(number: "01", kicker: "10 min", title: [What is CI/CD?])

#gh.alert-slide(
  title: [Code breaks when it meets other code],
  alerts: (
    ("Works on my machine", "warning", [You forgot to commit one file. Your laptop is fine. Everyone else's build is broken.]),
    ("Who broke main?", "warning", [Ten changes landed today. One of them is bad. Nobody knows which.]),
    ("Release day panic", "danger", [Shipping is a 20-step checklist that only one person remembers.]),
  ),
)

// The chef analogy from Grokking Continuous Delivery, chapter 1, retold.
// (Say the book's actual definition of CI out loud on this slide.)
#gh.content-slide(title: [Continuous integration (CI): the pasta sauce analogy])[
  #context {
    let ctx = gh._gh-state.get()
    let rule = (bottom: 1pt + ctx.palette.border-muted)
    let arrow = text(fill: ctx.palette.fg-subtle)[→]
    let head(emoji, body) = text(size: ctx.ts.small, weight: 600, fill: ctx.palette.fg-muted)[#text(font: "Noto Color Emoji", emoji) #body]
    set text(size: ctx.ts.small)
    grid(
      columns: (1fr, auto, 1fr),
      column-gutter: 20pt,
      inset: (y: 15pt),
      stroke: (x, y) => if y < 4 { rule },
      align: (left + horizon, center + horizon, left + horizon),
      head("🍝", [Holly the chef makes pasta sauce]), [], head("💻", [Your team builds software]),
      [She starts with raw ingredients: onions, garlic, tomatoes, spices], arrow, [Everyone's code changes],
      [She adds them one at a time, in the right order and amounts], arrow, [#gate[Integrate:] merge small changes often],
      [She takes a quick taste after every new ingredient], arrow, [#gate[Verify:] run the checks on every push],
      [If she only tasted at the end, it'd be too late to fix], arrow, [One giant merge the night before the deadline],
    )
    v(10pt)
    text(font: "JetBrains Mono", size: ctx.ts.micro, fill: ctx.palette.fg-subtle)[Analogy from Grokking Continuous Delivery, ch. 1 (Christie Wilson, Manning 2022)]
  }
]

#gh.two-col-slide(
  title: [You're doing continuous delivery (CD) when…],
  left: ("1 · Always shippable", "accent", "any commit", [You could safely release any commit on main, today. *How?* CI: every change has already passed the checks.]),
  right: ("2 · Shipping is easy", "warning", "1 click", [Releasing is as simple as pressing a button. *How?* Automate building, publishing and deploying.]),
)

#gh.table-slide(
  title: [Three terms, one abbreviation],
  headers: ("Term", "What it means"),
  columns: (1.6fr, 3fr),
  value-colors: (
    "integration": "accent",
    "delivery": "warning",
    "deployment": "warning",
    "CI/CD": "success",
  ),
  rows: (
    ("integration", "Every change is merged often and checked automatically"),
    ("delivery", "Main is always releasable; a person decides when to ship"),
    ("deployment", "Every change that passes the checks ships automatically"),
    ("CI/CD", "The umbrella term for the tools and automation behind all three"),
  ),
)

// =====================================================================
// Why bother
// =====================================================================

#gh.section-slide(number: "02", kicker: "10 min", title: [Why bother?])

#gh.ordered-slide(
  title: [Topher runs the pipeline by hand],
  items: (
    ([Once a day], [It breaks. Several people changed code yesterday. Whose change was it?]),
    ([On every change], [Teammates tell him when they push. Someone forgets.]),
    ([On git notifications], [The team grows. Running the pipeline becomes his whole job.]),
    ([With a webhook], [Every push triggers the pipeline, which emails whoever broke it. *GitHub Actions is this, ready-made.*]),
  ),
)

#gh.content-slide(title: [What a pipeline buys you])[
  #set list(spacing: 22pt)
  - *Fast feedback.* Find out in minutes, not at demo time, that a change broke something.
  - *Obvious culprits.* One run per change, so a red run points at one small change.
  - *Confidence.* Main stays green, so anyone can ship it without crossing their fingers.
  - *No boring toil.* Robots run the checks humans forget, every single time.
]

#gh.alert-slide(
  title: [The golden rule],
  alerts: (
    ("Caution", "danger", [*When the pipeline breaks, stop pushing changes.* Fix it first. Otherwise the next push gets the blame, and the original problem gets harder to untangle.]),
    ("Tip", "success", [Better still, run the checks _before_ you push. In our repo that's `npm run ci`.]),
  ),
)

// =====================================================================
// Anatomy of a pipeline
// =====================================================================

#gh.section-slide(number: "03", kicker: "15 min", title: [Anatomy of a pipeline])

#gh.content-slide(title: [Tasks are functions; pipelines call them])[
  #grid(
    columns: (1fr, 1.15fr),
    column-gutter: 36pt,
    [
      #gate[Task] \
      One thing to do: lint the code, run the tests, build the app.

      #v(12pt)
      #transform[Pipeline] \
      Runs the tasks in the right order, and stops when one fails.
    ],
    [
      ```python
      def pipeline(code):
          lint(code)
          run_tests(code)
          app = build(code)
          url = publish(app)
          deploy(url)
      ```
    ],
  )
]

#gh.table-slide(
  title: [Five tasks you'll see almost everywhere],
  headers: ("Task", "Kind", "What it does"),
  columns: (1fr, 1fr, 4fr),
  value-colors: (
    "lint": "accent",
    "test": "accent",
    "build": "warning",
    "publish": "warning",
    "deploy": "warning",
  ),
  rows: (
    ("lint", "gate", "Reads the code and flags mistakes, without running it"),
    ("test", "gate", "Runs the code and checks it does what we meant"),
    ("build", "transform", "Turns source into something runnable (TS → JS)"),
    ("publish", "transform", "Puts the build somewhere others can get it"),
    ("deploy", "transform", "Updates the running app to the new version"),
  ),
)

#gh.two-col-slide(
  title: [Gates check code; transformations change it],
  left: ("Gates · the CI part", "accent", "pass / fail", [*Lint, test.* Code goes in, a verdict comes out. A fail stops the pipeline.]),
  right: ("Transformations · the CD part", "warning", "code → app", [*Build, publish, deploy.* Code goes in, something new comes out. Gates always run first.]),
)

#gh.table-slide(
  title: [Same ideas, different names],
  headers: ("Idea", "GitHub Actions", "You may also hear"),
  columns: (1fr, 2.2fr, 1.8fr),
  value-colors: (:),
  rows: (
    ("pipeline", "workflow (.github/workflows/*.yaml)", "workflow, build"),
    ("task", "job, made of steps", "stage, step"),
    ("trigger", "on: push, pull_request", "webhook, event"),
    ("passes", "green tick on the commit", "\"CI is green\""),
    ("breaks", "red cross on the commit", "\"CI is red\""),
  ),
)

// =====================================================================
// The example app
// =====================================================================

#gh.section-slide(number: "04", kicker: "15 min", title: [Our example app])

#gh.content-slide(title: [Meet FizzBuzz Terminal])[
  #grid(
    columns: (1fr, 1.1fr),
    column-gutter: 36pt,
    [
      A tiny TypeScript web app. Type a number, press Enter:
      - ÷ 3 → *Fizz*
      - ÷ 5 → *Buzz*
      - ÷ both → *FizzBuzz*
      - anything else → the number
      - `0` quits
    ],
    gh.terminal-block(
      title: "localhost:8000",
      lines: (
        "Enter a number (0 to quit): 3",
        "Fizz",
        "Enter a number (0 to quit): 15",
        "FizzBuzz",
        "Enter a number (0 to quit): 7",
        "7",
        "Enter a number (0 to quit): 0",
        "Goodbye!",
      ),
    ),
  )
]

#gh.table-slide(
  title: [What's in the repo],
  headers: ("File", "What it does"),
  columns: (2.2fr, 3fr),
  value-colors: (".github/workflows/ci.yaml": "accent", "npm run ci": "success"),
  rows: (
    ("src/fizzbuzz.ts", "The FizzBuzz logic. No browser code."),
    ("src/main.ts", "The terminal: input, output, Run button"),
    ("tests/", "29 unit tests, written with Vitest"),
    ("biome.json", "Linter and formatter rules"),
    (".github/workflows/ci.yaml", "The pipeline"),
    ("npm run ci", "Runs what GitHub runs, on your laptop"),
  ),
)

#gh.content-slide(title: [The whole pipeline is one YAML file])[
  #grid(
    columns: (1.25fr, 1fr),
    column-gutter: 30pt,
    [
      ```yaml
      name: CI
      on: [push, pull_request]

      jobs:
        check:
          runs-on: ubuntu-24.04
          steps:
            - uses: actions/checkout@v5
            - uses: actions/setup-node@v5
            - run: npm ci
            - run: npm run typecheck
            - run: npm run lint
            - run: npm test
      ```
    ],
    [
      #set text(size: 19pt)
      #gate[`on:`] the trigger: every push and pull request.

      #gate[`runs-on:`] a fresh Linux machine, so no "works on my laptop".

      #gate[`npm ci`] installs the exact dependency versions.

      #gate[typecheck → lint → test] are the gates. Cheapest first; the first failure stops the run.
    ],
  )
]

#gh.content-slide(title: [Gate 1 · TypeScript catches the wrong kind of value])[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 24pt,
    [
      #label[you change src/fizzbuzz.ts]
      ```ts
      function fizzbuzz(n: number): string {
        // ...
        return n; // was: String(n)
      }
      ```
    ],
    [
      #label[npm run typecheck says]
      #gh.terminal-block(lines: (
        "src/fizzbuzz.ts(10,5):",
        text(fill: rgb("#f85149"))[error TS2322:],
        "Type 'number' is not",
        "assignable to type 'string'.",
      ))
    ],
  )
  #v(6pt)
  The function promises a string but returns a number. Caught in seconds, without running a single line.
]

#gh.content-slide(title: [Gate 2 · The linter flags risky code])[
  #grid(
    columns: (1fr, 1fr),
    column-gutter: 24pt,
    [
      #label[you change src/fizzbuzz.ts]
      ```ts
      if (n % 15 === 0) {
        return "FizzBuzz";
      } else if (n % 3 == 0) {
        return "Fizz";
      }
      ```
    ],
    [
      #label[npm run lint (Biome) says]
      #gh.terminal-block(lines: (
        "lint/suspicious/noDoubleEquals",
        text(fill: rgb("#f85149"))[× Using == may be unsafe],
        "  if you rely on type coercion.",
        text(fill: rgb("#4493f8"))[i Unsafe fix: use ===],
      ))
    ],
  )
  #v(6pt)
  `==` still works here, but it's a classic JavaScript trap. Linters also enforce formatting, so reviews argue about logic, not spaces.
]

#gh.content-slide(title: [Gate 3 · Tests check the code does what we meant])[
  #grid(
    columns: (1.1fr, 1fr),
    column-gutter: 24pt,
    [
      #label[tests/fizzbuzz.test.ts]
      ```ts
      it.each([
        [3, "Fizz"],
        [5, "Buzz"],
        [15, "FizzBuzz"],
      ])("fizzbuzz(%i) is %s", (n, want) => {
        expect(fizzbuzz(n)).toBe(want);
      });
      ```
    ],
    [
      #label[change n % 15 to n % 14]
      #gh.terminal-block(lines: (
        text(fill: rgb("#f85149"))[× fizzbuzz(15) is FizzBuzz],
        "Expected: \"FizzBuzz\"",
        "Received: \"Fizz\"",
        [Tests #text(fill: rgb("#f85149"))[5 failed] | 24 passed],
      ))
    ],
  )
  #v(6pt)
  The code is valid, so only a test that knows the right answer can catch this.
]

// =====================================================================
// Hands-on
// =====================================================================

#gh.section-slide(number: "05", kicker: "Hands-on · 25 min", title: [Break the build])

#gh.task-slide(
  title: [Break it → push → watch it go red → fix it],
  tasks: (
    (false, [Add `greet.ts`, import it, commit only `main.ts`], "→ typecheck"),
    (false, [Change `===` to `==` in `fizzbuzz.ts`], "→ lint"),
    (false, [Change `return String(n)` to `return n`], "→ typecheck"),
    (false, [Change `n % 15` to `n % 14`], "→ test"),
    (false, [Reword "Please enter a whole number."], "→ test"),
  ),
)

#gh.content-slide(title: [Adding CD: green on main? Ship it.])[
  #flow(("git push", none), ("check", "gate"), ("deploy", "transform"), ("you.github.io/introtocicd", none))

  #v(18pt)
  #set list(spacing: 22pt)
  - *Gates first:* `needs: check` makes deploy wait. A red check means nothing ships.
  - *Only main ships:* pull requests get checked, but only pushes to `main` deploy.
  - *One-time setup:* Settings → Pages → Source: GitHub Actions.
]

#gh.content-slide(title: [Add a deploy job to ci.yaml])[
  ```yaml
  deploy:
    needs: check                                # gates first
    if: github.ref == 'refs/heads/main'         # only ship main
    runs-on: ubuntu-24.04
    permissions: { contents: read, pages: write, id-token: write }
    environment: github-pages
    steps:
      - uses: actions/checkout@v5
      - run: npm ci && npm run build            # build
      - run: mkdir _site && cp -r src dist _site/
      - uses: actions/upload-pages-artifact@v5  # publish
        with: { path: _site }
      - uses: actions/deploy-pages@v5           # deploy
  ```
  #muted[Simplified. The full version is in `workshop/solution/ci.yaml`.]
]

// =====================================================================
// Wrap-up
// =====================================================================

#gh.content-slide(title: [Five things to take home])[
  + #gate[CI:] merge small changes often, and verify every one automatically.
  + #transform[CD:] main is always shippable, and shipping takes one button.
  + *Gates first:* lint and test, then build, publish and deploy.
  + *Automate the trigger:* every push runs the pipeline, so nobody has to be Topher.
  + *Red means stop:* fix the pipeline before pushing more. Run `npm run ci` first.
]

// =====================================================================
// Recommended reading
// =====================================================================

// One book per row: cover on the left, details on the right.
#let book(cover, title, byline, body) = context {
  let ctx = gh._gh-state.get()
  grid(
    columns: (140pt, 1fr),
    column-gutter: 28pt,
    align: horizon,
    box(stroke: 1pt + ctx.palette.border-default, image(cover, height: 170pt)),
    [
      #text(size: ctx.ts.subtitle, weight: 600)[#title] \
      #text(font: "JetBrains Mono", size: ctx.ts.micro, fill: ctx.accent)[#byline]
      #v(4pt)
      #text(size: ctx.ts.small, fill: ctx.palette.fg-muted)[#body]
    ],
  )
}

#gh.content-slide(title: [Recommended reading])[
  #book(
    "covers/grokking-continuous-delivery.jpg",
    [Grokking Continuous Delivery],
    "Christie Wilson · Manning, 2022",
    [A very beginner friendly book that explains stuff using analogies and images. I highly recommend this book, in this workshop we just covered chapter 2 but I'd recommend reading ahead for the extra content covered.],
  )
  #v(20pt)
  #book(
    "covers/continuous-delivery.jpg",
    [Continuous Delivery],
    "Jez Humble & David Farley · Addison-Wesley, 2010",
    [One of the most influential books on this topic, I have heard great things about this book but haven't read it yet, might be worth reading if you finish Grokking Continuous Delivery.],
  )
]

#gh.closing-slide(
  kicker: "## Thanks for coming",
  title: [Pizza time #text(font: "Noto Color Emoji")[🍕]],
  links: ("github.com/ProgSoc/introtocicd", "Quests.md"),
)
