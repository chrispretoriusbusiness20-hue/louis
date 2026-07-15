# Audit dimensions — sub-criteria and scoring anchors

Read this before scoring. Each dimension lists what to check and what a 0, 50, and 100 look like. Score to the anchors, not to vibes — every score should survive the client asking "why 62?"

Scoring mechanics:
- Assess each sub-criterion, then judge the dimension as a whole against the anchors. Sub-criteria are a checklist, not a formula — weight them by what matters for *this* business.
- If a dimension can't be assessed from available evidence, score it `n/a` and redistribute its weight proportionally across the remaining dimensions.
- Anchor scores are rungs, not the only legal values. A site between the 50 and 100 descriptions scores between 50 and 100.

---

## Marketing (25%)

What it assesses: positioning, offer clarity, conversion path, content, calls to action.

Sub-criteria:
- **Positioning** — can a first-time visitor say in 10 seconds what the business does, for whom, and why them?
- **Offer clarity** — are services/products named with concrete outcomes and (where sensible) prices, or is it "solutions"-speak?
- **Conversion path** — is there one obvious next step (book, call, quote, buy) reachable from every page in one click?
- **CTA quality** — specific and action-oriented ("Book a free 20-min consult") vs. generic ("Learn more", "Contact us") vs. absent.
- **Content** — does anything on the site answer the questions a buyer actually has (pricing, process, timelines, examples of work)?
- **Proof** — testimonials, case studies, before/after, client logos — anything that substantiates the offer.

Anchors:
- **0** — No coherent statement of what the business sells. No CTA anywhere, or the only contact path is a buried email address. No proof elements. Content is placeholder or years stale.
- **50** — The offer is discernible but generic; a competitor could run the same homepage. A contact form exists but nothing drives visitors to it. Some proof (a few testimonials) but unspecific. CTAs are "Contact us"-grade.
- **100** — Positioning is specific and differentiated in the hero. Every page has one clear next step. CTAs name the action and the payoff. Proof is concrete (named clients, numbers, outcomes). Content answers real buyer questions.

---

## Reputation (20%)

What it assesses: reviews, sentiment, owner responses, competitive standing.

Sub-criteria:
- **Volume & recency** — enough reviews to be credible, with recent ones (a great rating from 2019 is a liability).
- **Rating vs. local competitors** — 4.3 means different things next to a field of 3.8s vs. a field of 4.8s.
- **Sentiment themes** — what do reviewers repeatedly praise or complain about? Recurring complaints are findings.
- **Owner responses** — does the business respond at all, and does it respond well to negative reviews specifically?
- **Spread** — reviews on more than one platform (Google, industry-specific sites, Facebook) vs. all eggs in one basket.

Anchors:
- **0** — No reviews anywhere, or a rating under 3.5 with unanswered complaints, or credible signs of fake reviews.
- **50** — Decent rating (around 4.0–4.4) but thin volume, stale recency, or zero owner responses. Roughly par with competitors — reputation neither wins nor loses them business.
- **100** — 4.7+ with healthy volume and steady recency, thoughtful owner responses (especially to criticism), and a clear edge over local competitors on at least one platform.

`n/a` guidance: if you have only the website and can't see review platforms, this is `n/a` — do not infer reputation from testimonials the business curated itself.

---

## Discoverability (20%)

What it assesses: search and AI-answer visibility, structured data, local presence.

Sub-criteria:
- **Basic on-page SEO** — title tags, meta descriptions, one H1 per page, human-readable URLs.
- **Structured data** — schema.org markup (LocalBusiness, Product, FAQ, etc.) that search engines and AI assistants can parse.
- **Local presence** — Google Business Profile claimed, complete, and consistent with the site (name, address, phone, hours).
- **AI-answer visibility** — does the site state facts in extractable form (services, prices, service area, hours as text, not images)?
- **Indexability** — no accidental noindex, robots.txt blocks, or JS-only content that renders empty to crawlers.
- **Performance basics** — pages load fast enough not to be penalized; images sized sanely.

Anchors:
- **0** — Site is effectively invisible: not indexed or unfindable for its own brand name, no metadata, no business profile, key facts locked in images.
- **50** — Findable by brand name but not by service + location queries. Metadata present but templated ("Home | BusinessName"). Business profile exists but is incomplete or inconsistent with the site. No structured data.
- **100** — Ranks for realistic service + location queries, complete and consistent business profile, structured data on key pages, facts stated in crawlable text, clean indexing, fast pages.

---

## Sales readiness (20%)

What it assesses: decision-maker access, buying signals, budget capacity, existing stack.

Sub-criteria:
- **Decision-maker access** — is an owner or empowered manager identifiable and reachable?
- **Buying signals** — recent investment (new site, hiring, expansion, ad spend) suggesting appetite to spend.
- **Budget capacity** — staff size, number of locations, price points, market position — can they plausibly afford the work?
- **Existing stack** — what are they running (site platform, booking, CRM, analytics)? A migration-shaped mess is a cost; a modern stack with gaps is an opening.
- **Urgency** — a live event (rebrand, new location, bad review wave, seasonal peak) that makes "now" the answer.

Anchors:
- **0** — No identifiable decision-maker, no signs of spending on anything, price points that can't support agency fees, or a stack so tangled the first project is archaeology.
- **50** — An owner is findable but unproven as reachable. Business appears healthy but shows no recent investment. Budget is plausible but unconfirmed. Stack is workable.
- **100** — Named, reachable decision-maker; visible recent spend on marketing or tooling; clear budget capacity; a stack you can build on; and a live reason to act this quarter.

`n/a` guidance: usually not assessable from a website alone — needs the user's notes, LinkedIn, job postings, or ad libraries. Mark `n/a` rather than guessing.

---

## Compliance (15%)

What it assesses: privacy policy, cookie consent, accessibility, disclosures.

Sub-criteria:
- **Privacy policy** — present, linked from the footer, and actually describing what the site collects (forms, analytics, pixels).
- **Cookie consent** — if tracking scripts fire, is there a consent mechanism appropriate to the jurisdictions served?
- **Accessibility basics** — alt text on meaningful images, sufficient color contrast, keyboard-navigable menus and forms, labeled inputs.
- **Required disclosures** — industry/jurisdiction-specific: licensing numbers, terms of service, refund policies, affiliate disclosures where relevant.
- **Security surface** — HTTPS everywhere, no mixed content, forms submit over TLS.

Anchors:
- **0** — No privacy policy while collecting data via forms and trackers, no HTTPS, inaccessible to keyboard/screen-reader users, missing legally required disclosures.
- **50** — Boilerplate privacy policy that doesn't match actual tracking, consent banner present but non-functional (or absent where needed), scattered accessibility issues (missing alt text, low-contrast text), HTTPS fine.
- **100** — Accurate policy, working consent where required, no obvious accessibility failures on key pages, all expected disclosures present, clean HTTPS.

Note: compliance findings are often the easiest quick wins to sell — they're binary, checkable, and carry the word "risk" without you having to say it.
