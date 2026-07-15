---
name: agency-audit
description: Qualify a prospect, audit their business across five weighted dimensions into a single composite score, and turn the findings into a three-tier client proposal. Use this whenever the user is evaluating a potential client, sizing up a lead, auditing a business or its website, asking "is this a good prospect", scoring or comparing leads, building a pipeline view, or writing a proposal, pitch, or scope for agency services — even if they don't use the word "audit". Also use it when they paste a company URL and ask what they'd sell them.
---

# Agency Audit

A pipeline for turning "here's a business" into "here's what we'd sell them and why" — without hand-waving.

Three stages, in order: **qualify → audit → propose**. Each has an exit condition. Don't skip ahead: proposing to an unqualified lead wastes the best-looking work on the worst-fitting client, and a proposal with no scores behind it is just adjectives.

Run only the stage the user asked for. If they say "score this lead", stop after the audit. If they say "write a proposal", check whether audit data already exists in the conversation and reuse it rather than re-deriving it.

## Ground rules

**Never invent findings.** Every claim in an audit traces to something observed — the site, reviews, the user's own notes. If a dimension can't be assessed from available information, score it `n/a`, say why, and redistribute its weight across the rest. A fabricated 42/100 is worse than an honest "couldn't check."

**Say what you actually looked at.** Open every audit with a one-line evidence note: what was available, what wasn't. This is the difference between a report and a horoscope.

**Findings must be falsifiable.** "Weak brand presence" is unusable. "No meta description on the homepage; title tag is 'Home'" is a thing someone can go check and then pay to fix.

## Stage 1 — Qualify

Before any analysis, run the rubric. It takes a minute and saves days.

**All must be true:**
- The business is real and operating (recent activity, current hours, live listing)
- There's a reachable decision-maker — an owner or someone who can say yes
- There's a plausible budget signal (staff size, location, ad spend, price points)
- There's an actual gap you can bill for, not just a preference you have
- The work is something you'd want in your portfolio

**Auto-skip:**
- Chain or franchise location — decisions happen at corporate, not here
- Dormant: no reviews, posts, or updates in 12+ months
- No contact path to anyone with authority
- The "gap" is subjective taste (their site is fine, you just dislike it)
- Regulated work where a bug is a legal event, unless that's your specialty

**Exit condition:** if three or more qualifiers are vague or unknown, it isn't a prospect yet — it's a research task. Say so plainly and name the specific unknowns. Don't audit your way into a fantasy.

Output for this stage is short: **Qualified / Not yet / Skip**, one line of reasoning each, and the specific unknowns if any.

## Stage 2 — Audit

Five dimensions, weighted. The weights encode a claim: what a business can fix fastest and feel soonest matters more than what's technically most broken.

| Dimension | Weight | Assesses |
|---|---|---|
| Marketing | 25% | Positioning, offer clarity, conversion path, content, CTA |
| Reputation | 20% | Reviews, sentiment, owner responses, competitive standing |
| Discoverability | 20% | Search + AI-answer visibility, structured data, local presence |
| Sales readiness | 20% | Decision-maker access, buying signals, budget capacity, stack |
| Compliance | 15% | Privacy policy, cookie consent, accessibility, disclosures |

Read `references/dimensions.md` for the sub-criteria and what a 0 / 50 / 100 looks like on each. Do that before scoring — scoring from vibes produces numbers that don't survive a client asking "why 62?"

Score each dimension 0–100, then composite = the weighted sum, rounded. Grade: 90+ A, 75–89 B, 60–74 C, 40–59 D, under 40 F.

**A low composite is good news for you and bad news for them.** Frame it that way — a 40 is a business with more to gain, not a business to sneer at. Never write an audit whose subtext is "these people are idiots"; it leaks into the proposal and clients can smell it.

### Audit output format

```
# Audit — [Business name]
**Composite: XX/100 (Grade)**  ·  Evidence: [what was reviewed; what wasn't available]

## Scorecard
| Dimension | Score | Weight | Contribution |

## Critical findings
Three to five. Each: what's wrong · what it costs them · how you know.

## Quick wins
Two to three fixable in under a week. These are the proof-of-competence items.

## Opportunity
The one thing that, if fixed, moves the most revenue. Just one — a list of priorities is not a priority.
```

Keep the whole thing scannable. If the user is on mobile, lead with the composite and the single opportunity; offer the full table rather than dumping it.

## Stage 3 — Propose

A proposal converts findings into scope. The bridge is: **finding → consequence → service → price**. If a line item doesn't trace back to a numbered finding, cut it. That traceability is the entire persuasive mechanism — you're not selling services, you're selling the closure of gaps they just watched you find.

Three tiers, always. Read `references/proposal.md` for the full template, tier construction, and the ROI arithmetic before writing one.

Tier logic in brief:
- **Entry** — the quick wins, fixed price, low risk. Designed to be said yes to.
- **Core** — the critical findings. This is the one you want. Price it as the obvious middle.
- **Full** — Core plus the opportunity, retained. Priced so Core looks reasonable.

**On ROI projections:** state the assumption, then the arithmetic, then the range. "If the 4.2 → 4.6 rating lift moves conversion 1pt on ~300 monthly visits at your ~$180 ticket, that's ~$6.5k/yr against $2.4k of work." Never a bare number, never a promise. If you don't know their traffic or ticket size, ask for the two figures rather than inventing them — a fabricated ROI is the fastest way to lose a client in month three.

## When information is thin

Common case: the user has a URL and nothing else. Then:
- Audit what's observable (Marketing, Discoverability, Compliance are usually assessable from a site alone)
- Mark Reputation and Sales readiness `n/a` and redistribute
- Say what two or three facts would sharpen the audit most, and ask for them

This is more useful than a confident full score built on three-fifths of nothing.
