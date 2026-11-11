---
type: concept-explainer
title: "Example: Flat Domain — Notifications"
description: A worked leaf module with no decomposition — the standard template applied to a simple domain, the shape that fits most cases.
---

# Example: Flat Domain — Notifications

A simple domain that sends notifications. No sub-modules, no family — just the standard module template with the directories that earn their place.

This shape applies to most domains in a typical Laravel application.

## Shape

```
app/Modules/Notifications/
├── README.md
├── Public/
│   └── Services/
│       ├── NotificationDispatcher.php       ← public — outsiders trigger sends
│       └── PreferencesService.php           ← public — outsiders read/update prefs
├── Services/
│   └── TemplateRenderer.php                 ← internal — used by the dispatcher
├── Models/
│   ├── Notification.php
│   └── NotificationPreference.php
├── Data/
│   ├── SendNotificationData.php             ← input DTO
│   └── NotificationSentData.php             ← output DTO
├── Enums/
│   ├── Channel.php
│   └── Priority.php
├── Events/
│   └── NotificationSent.php
├── Exceptions/
│   └── NotificationDispatchFailed.php
└── Http/Controllers/
    └── PreferencesController.php
```

## README content

```markdown
# Notifications

Sends notifications to users across multiple channels (email, SMS, push) and manages user-level delivery preferences.

Public surface:
- NotificationDispatcher — send a notification to a user
- PreferencesService — read or update a user's preferences

Guarantees:
- A notification is delivered exactly once per recipient per channel
- Preference checks are applied at dispatch time, not at template-render time
```

## Why this shape

- **No `Modules/`.** The domain is small enough that all logic fits at the top level. Promoting `TemplateRenderer` to a sub-module would be ceremony for one helper.
- **No family module.** Channels (email/SMS/push) are values the dispatcher handles; no channel has code of its own here. The day a channel gets its own behaviour behind a shared contract, the channels are a family and each becomes a member module.
- **No `Contracts/`.** `NotificationDispatcher` has one implementation. The class itself is the contract.
- **No service provider.** Type-hinted constructor injection handles wiring; auto-discovery picks up listeners.
- **Internal `Services/` exists** because `TemplateRenderer` is used only by `NotificationDispatcher`. Promoting it to `Public/Services/` would expose internal mechanics callers shouldn't depend on.

## Where alternative shapes would be wrong

- **Adding `Modules/Email/` and `Modules/SMS/`** would split runtime channels into structural sub-modules. Channels are not slices of the domain, and in this module they are not yet a family in code either; they're values handled within the dispatcher. Sub-modules here would create three near-duplicate dispatchers.
- **Promoting `TemplateRenderer` to public** would expose template logic to callers, who would then start passing pre-rendered templates and bypassing preference checks.
- **Adding a `Contracts/NotificationDispatcherContract`** is shallow ceremony — there's one implementation. Mock the concrete class in tests; extract the interface only when a second implementation actually exists.

> **Changed 11 November 2026.** The wording "variants" and `Framework/` became "family". Reason: the variant layout is retired; kinds of one thing with their own behaviour are a family of member modules.
