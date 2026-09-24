---
title: Stripping non-digits from a pasted +91 number keeps the country code
status: confirmed
date: 2026-09-08
found_by: test run against LoginBloc
tags: [auth, login, input]
links: [../memory/2026-09-08-phone-normalisation-belongs-in-data.md]
---

## What we assumed

That normalising the phone field by dropping every non-digit was enough, and
that a pasted `+91 98765-43210` would "do the obvious thing".

## What actually happened

`+91 98765-43210` → digits `919876543210` → truncated to the first 10 →
**`9198765432`**. A number the Partner pasted correctly was silently mangled
into a different, valid-looking one.

## Why it was wrong

Truncation direction. An overlong value that came from a paste has its excess on
the *left* (the dial code); an overlong value that came from typing has it on
the right. The same code cannot treat both the same way.

## What changed

`LoginBloc._onPhoneChanged` trims from the left when the raw text starts with
`+`, and from the right otherwise. The `+` is the only signal used — no dial
code is compiled into the bloc.

## How we'd catch it earlier

Test input fields with paste-shaped values, not just typed ones. The typed case
passed from the first line of code; the pasted case never would have.
