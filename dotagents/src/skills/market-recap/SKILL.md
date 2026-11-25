---
name: market-recap
description: >-
  Produce a sourced US market and macro recap: what the S&P 500, Nasdaq, and
  Dow did and why, the biggest movers, breaking news, the latest inflation
  prints, the Fed's rate and calendar, and a full recession-indicator
  checklist ending in a yes or no verdict. Use when asked why the market is
  up or down, for a market recap or morning brief, what the Fed or inflation
  numbers are, when the next Fed meeting or data release is, or whether the
  US is in a recession.
---

# Market Recap

Answer three questions with numbers and a source for every number:

1. **What happened in the market?** Index moves, causes, movers, breaking news.
2. **Where are inflation and the Fed?** Latest prints, policy rate, calendar.
3. **Is the US in a recession?** Every indicator in the checklist, then a
   yes or no verdict.

The full indicator catalog, with definitions, thresholds, primary sources,
and FRED series IDs, is in [references/indicators.md](references/indicators.md).
Source tiers and the release calendar are in
[references/sources.md](references/sources.md). The output layout is in
[references/report-template.md](references/report-template.md). A complete
worked report is in [examples/2026-11-25.md](examples/2026-11-25.md).

## Hard rules

- **Never invent a number.** Every figure comes from a search result or page
  you read in this session, with its URL. If you cannot find a value, write
  "not found" in its row. Never estimate it from memory.
- **Use textbook definitions only.** Thresholds and interpretations come from
  the catalog in `references/indicators.md`. Do not add your own rules of
  thumb or forecasts.
- **Prefer primary sources.** BEA, BLS, the Federal Reserve, Treasury, ISM,
  Census, NBER, and FRED outrank news sites. A figure from a secondary source
  is marked "(secondary)". See `references/sources.md`.
- **Timestamp market data.** Intraday prices are snapshots. Say "as of" with
  the time, or "close" only when a closing print is confirmed.
- **Surface conflicts.** When sources disagree, show both values and say
  which one you trust and why. Drop stale or mismatched headlines and say you
  dropped them.
- **Name the publisher correctly.** PCE and GDP come from BEA, CPI and jobs
  from BLS, and the policy rate from the FOMC. The Fed uses PCE but does not
  publish it.
- **No advice.** Report the data and the textbook reading. Never recommend
  trades.

## Workflow

Load `WebSearch` first if it is deferred. Send independent searches in the
same turn. Use extended mode for same-day market news and for any figure that
standard mode returns thin or stale.

### 1. Market move

Search for today's session: index levels and percent changes for the S&P 500,
Nasdaq Composite, and Dow. Then search for the causes, the biggest S&P 500
decliners and gainers with percent moves, and the breaking news behind them
(data releases, policy announcements, earnings, company news). Note the
session context: holiday hours, a correction (10% or more below the record),
or a bear market (20% or more below).

### 2. Inflation and the Fed

Find the most recent release of each, with its release date and time:

- PCE and core PCE (BEA), year over year and month over month, against
  consensus. Note revisions to the prior month.
- CPI and core CPI (BLS), the same way.
- The federal funds target range, the date and vote of the last FOMC
  decision, any dissents, and the latest Summary of Economic Projections
  median. Confirm the range on federalreserve.gov.
- The next FOMC decision date and time, plus market-implied odds (CME
  FedWatch) with the date the odds were read.
- The next release date of PCE, CPI, the jobs report, and GDP.

### 3. Recession checklist

Fill **every row** of the checklist in `references/indicators.md`. For each
row record the latest value, its period, the threshold, whether it signals,
and the source URL. Do not skip a row because it is hard to find. Write "not
found" and keep going.

### 4. Verdict

- **Yes** only if NBER has declared a recession, or real GDP has fallen for
  two straight quarters, or a majority of the core signals (Sahm rule,
  payrolls, real income, real spending, industrial production, real GDP)
  are in recession territory.
- **No** when none of those hold. Name every indicator that is signaling, and
  the softest spot in the data, so the reader sees the risk.
- State that only the NBER officially dates US recessions, and that it does
  so months after the fact.

### 5. Deliver

Follow `references/report-template.md`. Lead with the one-line answer, then
the tables, then caveats, then the source list with every URL used. Keep chat
replies short and scannable. When Brian asks for a saved report, write it as
a Markdown file named `YYYY-MM-DD.md` using the same template.
