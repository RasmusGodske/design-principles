---
type: concept-explainer
title: "Example: Flat Domain — Notifications"
description: A worked leaf module with no decomposition — the standard template applied to a simple domain, the shape that fits most cases.
---

# Example: Flat Domain — Notifications

A simple domain that sends notifications. No sub-modules, no variants — just the standard module template with the directories that earn their place.

This shape applies to most domains in a typical application.

## Shape

```text
modules/notifications/
├── README.md
├── public/
│   └── services/
│       ├── NotificationDispatcher        ← public — outsiders trigger sends
│       └── PreferencesService            ← public — outsiders read/update prefs
├── services/
│   └── TemplateRenderer                  ← internal — used by the dispatcher
├── models/
│   ├── Notification
│   └── NotificationPreference
├── data/
│   ├── SendNotificationData              ← input value
│   └── NotificationSentData              ← output value
├── enums/
│   ├── Channel
│   └── Priority
├── events/
│   └── NotificationSent
├── exceptions/
│   └── NotificationDispatchFailed
└── entrypoints/http/
    └── PreferencesController
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

- **No `modules/`.** The domain is small enough that all logic fits at the top level. Promoting `TemplateRenderer` to a sub-module would be ceremony for one helper.
- **No `framework/`.** There is no variant axis. Channels (email/SMS/push) are runtime values handled by the dispatcher, not separate variants.
- **No `contracts/`.** `NotificationDispatcher` has one implementation. The class itself is the contract.
- **No wiring file.** Plain constructor injection (or whatever the stack's default resolution is) handles it; nothing needs manual registration.
- **Internal `services/` exists** because `TemplateRenderer` is used only by `NotificationDispatcher`. Promoting it to `public/services/` would expose internal mechanics callers shouldn't depend on.

## Where alternative shapes would be wrong

- **Adding `modules/email/` and `modules/sms/`** would split runtime channels into structural sub-modules. Channels are not variants of the *module*; they're values handled within the dispatcher. Sub-modules here would create three near-duplicate dispatchers.
- **Promoting `TemplateRenderer` to public** would expose template logic to callers, who would then start passing pre-rendered templates and bypassing preference checks.
- **Adding a `contracts/NotificationDispatcherContract`** is shallow ceremony — there's one implementation. Substitute the concrete class in tests; extract the interface only when a second implementation actually exists.
