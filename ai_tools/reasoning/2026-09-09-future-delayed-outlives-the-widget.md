---
title: A `Future.delayed` timer outlived the screen that started it
status: confirmed
date: 2026-09-09
found_by: widget test of the login flow
tags: [flutter, lifecycle, timers]
links: []
---

## What we assumed

That guarding a delayed callback with `if (!mounted) return` was enough to make
it safe — the callback checks whether the widget is still there before touching
it, so nothing can go wrong.

## What actually happened

The widget test failed before any assertion:

```
A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart': Failed assertion: '!timersPending'
```

The slow-line notice starts a 5 s timer when a request goes out. `mounted`
stopped the callback from *doing* anything, but the timer itself still existed,
still held the closure, and still fired.

## Why it was wrong

`Future.delayed` returns a future, not a handle — there is nothing to cancel.
The `mounted` check hides the leak rather than fixing it: in the app it is a
dead 5 s timer per abandoned request, which is invisible until something in the
closure holds a reference worth leaking.

## What changed

`_SlowLineNoticeState` keeps a `Timer?`, cancels it in `dispose` and on every
busy→idle transition, and starts a new one per request.

## How we'd catch it earlier

The framework already does — this is exactly what the pending-timer assertion is
for, and it only fires in a widget test. Any screen that starts a timer needs
one, even a shallow one that just pumps and settles.
