---
name: code-comments
description: Use when writing, editing, or reviewing code comments and API documentation in Hacki's Dart and Flutter code.
---

# Code comments in Hacki

Follow [Effective Dart: Documentation](https://dart.dev/effective-dart/documentation)
when working on comments in manually maintained Dart files. Keep its distinction
between rules, preferences, and suggestions; it does not require documenting
every declaration. Use the existing [flutter-style skill](../flutter-style/SKILL.md)
for broader code style.

## Before writing

- Read the implementation, nearby comments, and relevant callers or tests.
  Establish what the code actually guarantees before describing it. In
  particular, check error handling, asynchronous completion, and side effects.
- Choose the audience: use `//` for implementation rationale and `///` for a
  declaration's contract or usage. Explain constraints, surprising behavior,
  invariants, or reasons that names and types cannot convey.
- Prefer useful documentation for public APIs. Consider private API or
  library-level documentation when it helps explain shared concepts. Hacki
  disables `public_member_api_docs` in `analysis_options.yaml`; do not enable it
  or add boilerplate to every public member or Flutter override.
- Keep edits focused on the requested code. Preserve behavior, leave generated
  files to their generators, and avoid unrelated comment cleanup.

## Implementation comments

- Use `//`, not `/* ... */`, for explanatory comments. Block comments may be
  used temporarily to disable code, but do not leave commented-out code as
  documentation.
- Explain why a step exists or which constraint it preserves, rather than
  narrating assignments, loops, or method calls. Remove or correct stale
  comments when the implementation changes.
- Capitalize the first word unless it is a case-sensitive identifier, and end
  prose with punctuation. Apply this to fragments, inline comments, and TODOs.
- Keep wording short and precise. Avoid unfamiliar abbreviations. Use phrases
  such as "this repository" or "this item" when referring to the current
  instance so that the subject is clear.

For example, a refresh comment should explain why cached content stays visible,
not merely announce that a request is starting:

```dart
// Keep the cached feed visible so a failed refresh does not clear the screen.
```

Only use such a comment where the implementation supports that behavior.

## Dart documentation comments

- Put `///` documentation immediately before the declaration and before any
  annotations, including `@override` and `@Deprecated`. Avoid `/** ... */`.
- Open with a brief summary ending in a period. If more detail is needed, put
  a blank `///` line after the summary and continue in later paragraphs.
- Match the summary to the API's purpose:
  - Side-effecting methods: prefer a third-person verb, such as "Refreshes".
  - Values, non-boolean properties, and methods primarily returning values:
    prefer a noun phrase describing the result.
  - Boolean properties and boolean queries: prefer "Whether ...".
  - Types and libraries: prefer a noun phrase explaining their role; describe
    an instance of a type and its invariants where useful.
- Add information beyond the declaration's name, signature, or enclosing type.
  Explain meaningful input constraints, return semantics, exceptions, and
  side effects in prose, without JavaDoc-style `@param`, `@returns`, or
  `@throws` tags. Do not invent guarantees or document hypothetical errors.
- Use `[identifier]` for parameters and other identifiers that resolve in
  scope. Use qualified references such as `[Duration.inSeconds]` for members
  of other types. Use backticks for literals or code that should not be linked.
- Document a getter/setter pair once, usually on the getter, including any
  relevant constraints on setting the value.
- Use simple Markdown and avoid HTML formatting. Include a small example only
  when it makes usage clearer; use backtick fences with a language label.

This illustrative helper shows a result-oriented summary, a separate detail
paragraph, identifier references, and an exception described in prose:

```dart
/// The first [limit] story identifiers in their original order.
///
/// Returns all identifiers when [limit] exceeds the length of [storyIds].
/// Throws an [ArgumentError] when [limit] is negative.
List<int> selectStoryIds(List<int> storyIds, int limit) {
  if (limit < 0) {
    throw ArgumentError.value(limit, 'limit', 'Must be non-negative.');
  }
  return storyIds.take(limit).toList();
}
```

## Review and validation

- Re-read each comment alongside the final code. Check that names, conditions,
  units, error behavior, and completion claims remain accurate; remove
  repetition that adds no context.
- Verify bracket references resolve and any examples match the documented API.
  Check summary paragraphs, annotation placement, punctuation, and Markdown.
- Run `git diff --check`. For Dart edits, follow the formatting, analyzer, and
  relevant test guidance in [flutter-style](../flutter-style/SKILL.md), including
  checking documentation reference diagnostics. A skill-only Markdown change
  does not need Flutter builds or tests. Report the checks actually run.
