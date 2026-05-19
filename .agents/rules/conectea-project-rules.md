---
trigger: always_on
---

# ConeCTEA — Project Rules

Mandatory rules for any agent, assistant, or implementation tool working on the ConeCTEA project.

Goal: protect scope, avoid accidental changes, preserve product decisions, and keep the project stable, secure, auditable, and consistent.

---

## 1. Language

Always communicate with Lucas in Brazilian Portuguese.

All explanations, reports, confirmations, warnings, plans, and questions must be written in pt-BR.

Code, commands, file names, package names, columns, logs, stack traces, and technical identifiers may remain in English when necessary.

Do not switch to English unless Lucas explicitly asks for English output or translation.

---

## 2. Core Behavior

Do exactly what was requested.

Do not modify unrelated files, methods, widgets, routes, logic, styles, database structures, documentation, or project architecture.

Before making changes, identify the exact files and methods/components that will be changed.

If the task affects only one method, widget, component, or file, modify only that target.

Do not refactor, rewrite, reorganize, rename, remove, simplify, optimize, format, migrate, or redesign anything outside the explicit task.

Do not perform opportunistic cleanup.

If another file or area seems necessary, stop and ask Lucas before proceeding.

If the scope is unclear, ask before editing.

---

## 3. Scope Control

Authorized files are a hard limit.

Never change these areas unless explicitly authorized:

- Supabase schema
- migrations
- RLS, policies, grants
- database triggers, functions, views, RPCs
- Edge Functions
- AuthService
- DatabaseService
- models
- routes
- navigation guards
- assets
- Android native files
- Gradle files
- README.md
- DOCTecnico.md
- documentation files

Exception: if the prompt explicitly authorizes one of these areas, change only the authorized target.

---

## 4. No Hidden Work

Do not create temporary files, scratch files, generated files, reports, or analysis files inside the repository unless explicitly requested.

Never create `analysis_results.md`.

Do not leave dead code, unused imports, fake data, test buttons, debug-only widgets, or temporary TODOs.

Do not add logs exposing CPF, e-mail, phone, document URLs, Drive URLs, Base64 content, names in sensitive contexts, or private user data.

---

## 5. Product Identity

ConeCTEA is a social, institutional, and administrative app for Família TEA Bauru.

ConeCTEA is not a medical app.

ConeCTEA does not diagnose, treat, prescribe, triage, or replace professional healthcare.

The Digital ConeCTEA Card:

- is not official CIPTEA;
- does not replace CIPTEA;
- does not replace RG, CPF, CNH, medical reports, or any official document;
- is an internal/community card connected to the Família TEA Bauru ecosystem.

Never write UI text or documentation implying that ConeCTEA issues official government documents.

Never write UI text or documentation implying that ConeCTEA provides medical diagnosis, treatment, prescription, or clinical validation.

---

## 6. Design System

The project follows the Night Blue / Dark Glass Premium identity.

Before creating or modifying UI, check existing premium components and tokens.

Prefer existing shared components and tokens:

- AppColors
- ConecteaVisualTokens
- StatusVisualTokens
- AppTextStyles
- premium widgets
- Night Blue backgrounds
- Dark Glass cards
- subtle borders
- semantic colors
- mobile-first layouts

Do not introduce generic Material UI, default AlertDialogs, dry ListTiles, bright blue inputs, or arbitrary hardcoded colors when a premium pattern already exists.

Status-related actions should use StatusVisualTokens when appropriate.

Neutral actions such as visualization, privacy, restriction, support, and maintenance should use ConecteaVisualTokens when available.

---

## 7. Mobile-First

The app must work well on real Android devices, especially around 360dp width.

Always consider narrow phones, display zoom, and font scaling.

Avoid fixed widths that can cause overflow.

Use Flexible, Expanded, Wrap, SingleChildScrollView, SafeArea, LayoutBuilder, and constraints when appropriate.

Dialogs, sheets, and forms affected by the keyboard must be scrollable and keyboard-aware.

Do not introduce horizontal or vertical overflow.

---

## 8. Privacy and LGPD

Treat user data as sensitive by default.

Sensitive data includes:

- CPF
- e-mail
- phone
- personal names in sensitive contexts
- medical reports
- documents
- Drive/document URLs
- member/dependent data
- autism/disability-related eligibility data

Do not expose sensitive data in logs, reports, screenshots, or debug messages.

Database audits must use schema information and aggregated counts only, unless Lucas explicitly authorizes otherwise.

Document and medical report flows must preserve the rule that sensitive files are used for administrative validation and removed after approval when applicable.

---

## 9. Supabase and Backend

Do not alter Supabase remotely unless explicitly instructed.

Do not apply SQL, migrations, RLS changes, triggers, functions, views, RPCs, policies, grants, inserts, updates, or deletes without explicit permission.

If a task involves migration:

1. Create the migration locally only if authorized.
2. Do not apply it remotely unless Lucas explicitly says so.
3. Show the SQL for review before execution.
4. Do not expose real user data.
5. Clearly state whether the migration was applied manually or not.

When using Supabase MCP:

- use read-only access unless explicitly authorized;
- do not run mutations without permission;
- do not return personal data in reports.

---

## 10. Realtime and Streams

Do not create Supabase streams directly inside `build()` when they can be stabilized in State.

Initialize streams in `initState()` or in a controlled loading method.

Manual `.listen()` calls must store a `StreamSubscription` and cancel it in `dispose()`.

User-specific streams should filter in Supabase by `user_id` whenever applicable.

Avoid client-side N+1 enrichment loops in Realtime streams.

Do not replace Realtime with polling, FutureBuilder, or cache unless explicitly authorized.

Do not create StreamController or manual subscriptions unless necessary and authorized.

---

## 11. Authentication and Permissions

Do not alter authentication, roles, permissions, or admin hierarchy unless explicitly requested.

Current role concepts:

- user
- admin
- admin_master
- admin_dev

Do not change UserRole, route guards, admin access, or permission rules without explicit authorization.

Do not make role changes Realtime unless requested.

Do not assume client-side permission checks are enough for sensitive operations.

---

## 12. Documentation

Do not edit documentation unless the task is specifically a documentation task.

If editing docs:

- change only authorized files;
- do not rewrite entire files unless requested;
- do not alter README.md or DOCTecnico.md without authorization;
- keep checkpoint documentation concise and factual;
- run `git diff --check`;
- avoid trailing whitespace.

Do not claim that something is final, perfect, risk-free, fully secure, or definitive unless it was proven and approved.

---

## 13. Git Discipline

Never use `git add .` or `git add -A`.

Always stage files by explicit path.

Before staging, report:

- `git status --short`
- `git diff --check`
- `git diff --name-only`
- `git diff --stat`

For code changes, also run:

- `flutter analyze`
- `flutter build apk --debug`

For documentation-only changes, do not run Flutter commands unless explicitly requested.

Before commit, confirm:

- `git diff --cached --name-only`
- `git diff --cached --stat`
- `git diff --cached --check`

Only commit after Lucas explicitly approves the visual or functional result.

Only push when requested.

After push, confirm `git status --short`.

---

## 14. Validation

For code changes, normal validation requires:

- `flutter analyze`
- `flutter build apk --debug`
- `git diff --check`
- `git diff --name-only`
- `git diff --stat`
- `git status --short`

For documentation changes, normal validation requires:

- `git diff --check`
- `git diff --name-only`
- `git diff --stat`
- `git status --short`

Do not run `flutter run`, ADB, or emulator commands unless explicitly authorized.

Do not claim visual validation was performed unless Lucas performed it or provided evidence.

---

## 15. Reports

Reports must be factual and scoped.

Every report should include:

- files changed;
- what changed;
- what did not change;
- validations executed;
- Git status;
- whether staging, commit, or push happened;
- confirmation that `git add .` was not used;
- confirmation that unrelated areas were not touched.

Avoid exaggerated language:

- absolute success
- perfect
- impeccable
- fully protected
- zero risk
- total guarantee
- definitive

Prefer objective terms:

- completed
- validated
- preserved
- unchanged
- found
- not found
- pending
- requires Lucas validation

---

## 16. Legal and UI Text

Texts about account, privacy, documents, card requests, and consent must be clear.

The app must clearly explain:

- why CPF is requested;
- why a photo ID document is requested;
- why a medical report may be requested;
- who can access submitted documents;
- documents are used for administrative validation;
- sensitive documents are removed after approval when applicable;
- the ConeCTEA card is not CIPTEA;
- the ConeCTEA card does not replace official documents;
- the app is social, institutional, and administrative, not medical.

Do not write legal or privacy promises that are not actually implemented.

If a statement depends on backend behavior, verify the implementation before writing it as fact.

---

## 17. Current Project Direction

The Realtime/performance front was completed and documented.

Technical Maintenance Center is paused until the future security/feature flags front.

The next major front is User Center.

User Center must be a trust and account hub and may include:

- Account / Data
- Security and Privacy
- Terms of Use
- Privacy Policy
- Consents
- Account/data deletion
- About ConeCTEA
- About Família TEA Bauru
- Official channels
- How user data is used
- Information about the Digital ConeCTEA Card

Before implementing User Center, perform an audit-only mapping of existing files, routes, buttons, placeholders, services, and privacy risks.

Do not start implementing User Center without an audit.

---

## 18. Safety Stop

Stop and ask Lucas if:

- a required file is outside the authorized scope;
- the task requires database, migration, RLS, or backend work;
- a change may affect user data;
- a change may expose sensitive data;
- validation fails;
- unexpected files appear in Git;
- implementation requires assumptions;
- a change may affect another screen or flow.

When in doubt, stop and report.