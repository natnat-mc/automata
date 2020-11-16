# Automata
A small library for building push-down automata

## How do I do this?
- Using the DSL, in `.moon` files
- Writing the transition functions, initial and final states manually in a `.lua` file
- With a syntax language at some point

## What kind of automata are implemented?
Only deterministic push-down automata work so far.
This also means you can write deterministic finite state automata since they are strictly a subset.

## Will you add support for nondeterministic automata?
Maybe, but only through determinisation and not backtracking.
The runtime should remain the same, since it's O(n) and compiling the automate should hopefully only happen once so it's allowed to be slower.
This will probably come with restrictions, such as no `\enter` or `\exit` handlers.

## Regex syntax?
Hopefully soon.
But I need a determinisation algorithm first before I can do this, since (most) regexes are translated to nondeterministic finite state automata.

## Other transition types?
Ideally anything that can be matched with a regex should be allowed as a transition.
This includes regexes, character classes (though that is already the case) and also literal strings.
This also depends on the determinisation algorithm, and may come with additional restrictions (like no `\exit` handler or only `@char` for transitions).
