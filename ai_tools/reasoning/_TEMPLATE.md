---
title: What we believed, and what turned out to be true
status: confirmed       # confirmed (reproduced) · suspected (seen once)
date: YYYY-MM-DD
found_by: test run / live probe / device testing / user report
tags: [api, auth]
links: []
---

## What we assumed

The belief the code was written against. State it plainly, including that it was
reasonable at the time — this folder is a record, not a blame ledger.

## What actually happened

The observation. Include the real evidence: the request, the response, the exact
status code, the error text, the timing. Verbatim beats paraphrase, because the
next person needs to recognise it when they see it again.

## Why it was wrong

The gap between the two. Usually an undocumented behaviour, an assumption about
a dependency, or a default nobody chose.

## What changed

The fix, and where. If it changed a decision, link the `memory/` entry; if it
suggested one, link the `proposals/` entry.

## How we'd catch it earlier

The check, probe or test that would have surfaced this before the code was
written. This line is the whole reason the folder exists.
