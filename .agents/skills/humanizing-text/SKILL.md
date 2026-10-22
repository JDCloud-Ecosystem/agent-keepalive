---
name: humanizing-text
description: >
  Use when writing or editing any prose or user-visible text, meaning docs/, a spec, an
  ADR, a README, a chat explanation, or a screen of keepalive. Detects the
  statistical markers of generated text and rewrites them into the fact underneath,
  keeping the prose warm and readable. Runs a second pass, because the first rewrite
  reintroduces the patterns.
---

# Humanizing Text

## Overview

Generated prose has a signature. It inflates significance, promotes instead of stating,
groups ideas in threes, attributes to nobody, and closes by offering further help. None of
it is wrong exactly, which is why it survives a reread. It is filler sitting where the
fact should be.

**Core principle.** Every marker goes away by putting the concrete thing in its place.
Cut the inflation and either a fact appears, or the sentence had nothing to say and it
goes.

**The other half of the principle, and the one that gets forgotten.** The target is prose
a colleague would write, not prose stripped to a telegram. A rewrite where every sentence
is five words long and every verb is an order has traded one signature for another. Keep
the connectives, keep a subordinate clause when the thought has two halves, and let the
reader be walked through the idea rather than handed a list of commands.

This skill is cross-cutting. It runs inside whatever phase produced the text, not as a
separate stage bolted on at the end.

## When to Use

- Writing or editing anything under `docs/`, meaning guides, READMEs, ADRs and onboarding material.
- Writing a spec in `docs/specs/`, or adding a section to one.
- Writing a commit guide note, an issue, a pull request body, or a comment a person will read.
- Writing or editing what keepalive shows on screen, the `U_` strings of `lib/screens.sh` and the texts of each
  script.
- Editing prose that already exists. Touch a paragraph, humanize that paragraph. Boy Scout rule, not a sweep of the whole file.
- The developer says a text sounds like AI, or asks for something that reads more human.

**Not for** identifiers, code comments, commit messages, variable names,
log lines, or anything with a fixed grammar. Those are English and format-bound, and this
skill leaves them alone.

## Process

### 1. Read the text against the word-level table

| Pattern                    | Avoid                                                       | Use instead                           |
| -------------------------- | ----------------------------------------------------------- | ------------------------------------- |
| Significance inflation     | «marca un momento crucial en la evolución de»               | The fact and its date                 |
| Promotional language       | «enclavado en la impresionante región de»                   | «es una ciudad de»                    |
| Forced rule of three       | «innovación, inspiración e ideas»                           | However many items there actually are |
| Vague attribution          | «los expertos consideran que»                               | The source, with its date             |
| Chatbot artifact           | «Espero que te sirva, avísame si»                           | Nothing                               |
| Analytical gerund, no data | «reflejando, mostrando, simbolizando»                       | The data                              |
| Marked vocabulary          | «además», «crucial», «panorama», «profundizar», «navegar»   | The plain word                        |
| Announced importance       | «es importante destacar que», «cabe mencionar que»          | The sentence without the preamble     |
| Stacked hedging            | «podría potencialmente llegar a fallar»                     | «falla cuando X»                      |
| Filler                     | «con el fin de», «en este momento del tiempo»               | «para», «ahora»                       |
| Not only but also          | «no solo valida el CP, sino que también rellena la colonia» | Two sentences, or one joined by «y»   |

### 2. Read it again against the structural table

These are the ones a word-level pass never catches, and the ones that make a text feel
mechanical even after every phrase above is gone.

| Pattern            | How it shows up                                                  | What to do                                 |
| ------------------ | ---------------------------------------------------------------- | ------------------------------------------ |
| Uniform rhythm     | Every sentence between fifteen and twenty words                  | Alternate a short sentence with a long one |
| Binary contrast    | «No es X. Es Y.», repeated as a rhetorical tic                   | Say what it is, once                       |
| Parallel openings  | Three consecutive sentences starting the same way                | Vary the entry, or merge them              |
| Colon splice       | A setup and its payoff joined mid-sentence by a colon            | A comma, a period, or a rewritten clause   |
| Cascading em dash  | Three or more in one paragraph                                   | Comma, period or parentheses               |
| Mechanical bold    | Bold on a phrase that carries no more weight than its neighbours | Plain text                                 |
| Generic conclusion | A closing paragraph that would fit any document                  | Delete it, or end on the last real point   |

Punctuation is governed by [`CLAUDE.md`](../../../CLAUDE.md) → "Writing style", which owns
the em dash, the colon and the list rules. Read it there. This skill applies that rule and
does not restate it.

### 3. Rewrite by replacement, not by amputation

For each marker, ask what fact it was standing in for, and put that fact in. When there is
no fact behind it, the sentence goes. A paragraph that halves after this step was mostly
scaffolding, and that is a good outcome.

Keep the technical precision. A rewrite that reads better and says less is the worse text
of the two.

### 4. Check the temperature before moving on

Reread what you wrote and ask whether a person would say it that way to a colleague at a
desk. Softness is not padding. It is the connective tissue that lets a reader follow a
chain of reasoning without rereading each sentence. When the rewrite has come out clipped,
put one connective back and let a sentence run long.

### 5. Second pass, always

Run both tables over the rewritten text. This is not optional. The rewrite was generated
the same way the original was, so it reintroduces the same patterns, and usually different
ones from the first round.

### 6. Read it out loud, in your head

A sentence you would not say to a colleague does not belong in a doc either. This is the
cheapest check of the six and it catches what the tables miss.

## Rationalizations

| Excuse                                         | Reality                                                                          |
| ---------------------------------------------- | -------------------------------------------------------------------------------- |
| "It reads fine, no markers here"               | Run both tables. "Reads fine" is what the markers are optimized for              |
| "It is technical writing, it sounds like that" | Technical writing is dense, not inflated. `docs/CODE-STYLE.md` is the reference  |
| "The second pass will not find anything"       | It finds something almost every time, which is why it is in the process          |
| "Short sentences are always clearer"           | Uniform length is its own tell. Vary it, and the reader stops noticing the prose |
| "Cutting it loses nuance"                      | Check whether the nuance is a fact. If it is not, it was padding                 |
| "The colon reads better here"                  | Mid-sentence it splices setup onto payoff. `CLAUDE.md` decides, not taste        |
| "It is only a commit guide note"               | A person reads it, and it decides what they run                                  |

## Red Flags

- A paragraph that could open any document in any project.
- A list where every item ends in "— explanation".
- Three adjectives where the text needed one number.
- A closing line offering more help, in a document nobody can reply to.
- An intensifier carrying the sentence, such as «robusto», «potente», «impresionante» or «crucial».
- The rewrite came out the same length as the original, item for item.
- The rewrite reads like a set of orders, with no sentence longer than a line. Over-correction.
- Only one pass ran.

## Verification

Before calling the text done:

- Name the patterns found, by row of either table. "None found" on a first pass over generated text means the tables were not really applied.
- Confirm the second pass ran, and say what it caught.
- Confirm the result still has rhythm. Two consecutive paragraphs of uniformly short sentences fail this.
- Confirm no identifier, commit message, variable name or log line was touched.
- For text on a screen, confirm it is still Mexican Spanish, has no colon or semicolon inside a sentence, and
  still fits a 72-column terminal.
- For prose under `docs/`, open every relative link, since a rewrite that cuts a sentence often cuts the link inside it.

## Project Context

**Language.** Specs, ADRs and `docs/` are Spanish. Code, comments, commit messages and the files under
`.agents/skills/` are English. Everything keepalive shows is Spanish, the only language it has, and the log
lines stay English because scripts read them. This skill never moves a text across that line.

**Punctuation and lists.** [`CLAUDE.md`](../../../CLAUDE.md) → "Writing style" owns them.

**Clean edits.** A rewrite leaves the new state as if written from scratch, and never references the
previous wording inside the file. The reason for the change goes in the chat or the commit guide.

**What this skill deliberately does not take from the public humanizers.** The published skills for this
job aim at blog posts and marketing copy, so some of their advice works against a technical repository.

| Their advice                                         | Why it is not adopted here                                                          |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Turn every bullet list into flowing prose            | `CLAUDE.md` prefers tight bullets, and `AGENTS.md` is mostly tables                 |
| Add conversational fillers and first-person opinion  | A spec is read to be executed                                                       |
| Introduce deliberate typos and small inconsistencies | Prettier reverts them, and a doc that hedges its own facts misleads the next reader |
| One rewrite pass is enough                           | The second pass catches what the first reintroduced. It stays mandatory here        |
