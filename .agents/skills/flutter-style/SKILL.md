---
name: flutter-style
description: Keep Flutter and Dart changes consistent with Hacki's existing code style and architecture.
---

# Flutter and Dart style in Hacki

Use this skill when creating, editing, or reviewing Dart code under `lib/`.
Treat nearby code in the same feature as the primary reference; this codebase has
established patterns, but some older features differ. Match the local pattern
unless the task explicitly calls for an architectural change.

## Before changing code

- Read the target file, its nearest peers, and any relevant barrel file before
  choosing a pattern. Prefer a small change that fits the existing structure.
- Keep responsibilities in the existing layers: screens and widgets render UI,
  Cubits/BLoCs coordinate app state, repositories handle data access, services
  handle platform or infrastructure concerns, and models represent app data.
- Do not move unrelated code or introduce a new state-management, dependency
  injection, or model-generation approach just to make a local change uniform.

## Project conventions

- Follow `analysis_options.yaml` and the repository's `very_good_analysis`
  rules. In particular, `always_specify_types` is enabled. Use explicit types
  for declarations and callbacks, and let `dart format` determine whitespace
  and line wrapping.
- Use `UpperCamelCase` for types, `lowerCamelCase` for members and variables,
  and `_lowerCamelCase` for library-private members. Name screens with a
  `Screen` suffix; use descriptive, feature-oriented file and directory names.
- Keep feature-specific screens and widgets together under
  `lib/screens/<feature>/`; put reusable app-wide widgets under
  `lib/screens/widgets/`. Follow nearby `widgets.dart` or layer barrel exports
  where they already exist instead of adding redundant exports.
- Use package imports for app code (`package:hacki/...`) and preserve the
  project's import grouping and ordering. Use existing barrel imports for
  shared layers when the neighboring files do.
- Use `flutter_bloc` for state management. Follow the feature's established
  Cubit or BLoC shape and keep presentation state separate from widgets. State
  objects commonly use `Equatable`, final fields, and `copyWith`; match the
  local state representation and status handling rather than introducing a
  competing pattern.
- Keep dependencies injectable through constructors where that is the local
  pattern. The app uses `locator` from `lib/config/locator.dart`, often as a
  default for optional repository or service dependencies. Reuse that setup;
  don't add a second service locator.
- Preserve existing logging and error-handling conventions, including the
  `Loggable` mixin where used. Do not silently swallow errors or turn failures
  into success-shaped state.
- Keep shared visual constants and theme choices in `lib/styles/` and use
  existing dimensions, colors, and style helpers instead of adding duplicate
  values.

## Working and validating

- Prefer the smallest change that preserves the surrounding UX and architecture.
  Avoid broad renames, unrelated cleanup, and speculative consistency fixes.
- If adding behavior, update or add focused tests alongside the feature using
  the repository's existing test patterns.
- Format changed Dart files with `dart format`, then run `flutter analyze` and
  the most relevant tests when available. Resolve issues introduced by the
  change; don't claim checks passed unless they were run.

## Examples to consult

- App setup and provider wiring: `lib/main.dart`
- Feature screens and local widgets: `lib/screens/home/home_screen.dart`
- Cubit and colocated state: `lib/cubits/fav/fav_cubit.dart` and
  `lib/cubits/fav/fav_state.dart`
- Repository data access: `lib/repositories/hacker_news_repository.dart`
- Analyzer configuration: `analysis_options.yaml`
