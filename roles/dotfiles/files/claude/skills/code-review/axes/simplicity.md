# Simplicity axis

Could the diff do the same thing with less code, fewer moving parts, or code that explains itself?

A documented repo standard always wins: where it endorses something this axis would flag, suppress the finding.

## Smell baseline

A fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when a repo documents nothing. Each reads *what it is* → *how to fix*; match it against the diff and label it as a heuristic ("possible Feature Envy").

- **Mysterious Name** — a function, variable, or type whose name doesn't reveal what it does or holds. → rename it; if no honest name comes, the design's murky.
- **Duplicated Code** — the same logic shape appears in more than one hunk or file in the change. → extract the shared shape, call it from both.
- **Feature Envy** — a method that reaches into another object's data more than its own. → move the method onto the data it envies.
- **Data Clumps** — the same few fields or params keep travelling together (a type wanting to be born). → bundle them into one type, pass that.
- **Primitive Obsession** — a primitive or string standing in for a domain concept that deserves its own type. → give the concept its own small type.
- **Repeated Switches** — the same `switch`/`if`-cascade on the same type recurs across the change. → replace with polymorphism, or one map both sites share.
- **Shotgun Surgery** — one logical change forces scattered edits across many files in the diff. → gather what changes together into one module.
- **Divergent Change** — one file or module is edited for several unrelated reasons. → split so each module changes for one reason.
- **Speculative Generality** — abstraction, parameters, options, or hooks added for needs the spec doesn't have (one caller, one value). → delete it; inline back until a real need shows.
- **Message Chains** — long `a.b().c().d()` navigation the caller shouldn't depend on. → hide the walk behind one method on the first object.
- **Middle Man** — a class or function that mostly just delegates onward. → cut it, call the real target direct.
- **Refused Bequest** — a subclass or implementer that ignores or overrides most of what it inherits. → drop the inheritance, use composition.

## Less code

- **Dead code** — branches that cannot be reached, or exports, parameters, variables the diff adds but nothing uses.
- **Reimplementation** — logic that already exists in the repo or its dependencies. Name the existing function.
- **Defence against impossible states** — guards for states the types or callers already rule out.

## Comments that code could replace

For each comment the diff adds or changes, ask whether a code change would make it unnecessary: a rename, a type (union, branded type), extracting a function or constant, or restructuring a branch. If so, put the concrete rewrite (new name, new type) in the suggestion.

Do not flag a WHY that code cannot express: external constraints, ordering dependencies, references to ADRs or issues.

## Severity

- **must-fix**
  - Dead code
  - Reimplementation of something that already exists
  - Speculative Generality
  - A comment that restates WHAT the code does, or that apologises for an inaccurate name or type
- **nit** — every other smell, and a WHY comment that code could partly absorb.
