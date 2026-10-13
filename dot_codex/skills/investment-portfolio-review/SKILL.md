---
name: investment-portfolio-review
description: Analyze a current brokerage portfolio for total return, dividend and distribution quality, concentration, overlap, leverage, and fit with an income or growth objective. Use for portfolio checkups, dividend-reinvestment plans, leverage reviews, or position-level risk analysis; do not use to execute trades.
---

# Investment Portfolio Review

Produce a dated, evidence-backed review of the user's current portfolio. Separate cash flow from economic return and distinguish reinvesting distributions from borrowing or leveraged products.

## Acquire the snapshot

- Prefer the user's authorized, already authenticated brokerage session. For Toss Securities WTS, use BrowserOS read-only inspection when available.
- Record the as-of time, account scope, display currency, cash balances, FX rate, and whether fees, taxes, dividends, and distributions are included.
- Normalize each holding to symbol, name, quantity, market value, cost basis, unrealized P/L, daily P/L, and cumulative cash distributions when available.
- Do not submit orders, modify the account, or extend authorization beyond analysis. Never place credentials, identity data, cookies, or portfolio snapshots in the skill or dotfiles.
- Do not persist holdings unless the user explicitly asks. If persistence is requested, treat the snapshot as sensitive and use the configured encrypted secret workflow rather than plaintext chezmoi files.

## Calculate before interpreting

Use `scripts/portfolio_metrics.py` for deterministic calculations when normalized holdings are available. Report at least:

- position weights and top-one/top-two concentration;
- each position's contribution to total unrealized P/L;
- cash weight when account-level cash is known;
- total return including distributions when the brokerage P/L excludes them;
- break-even recovery percentage only when it clarifies downside asymmetry;
- explicit product leverage and an approximate exposure view, clearly labeled as an estimate.

Do not count a distribution as investment return without accounting for price/NAV change, taxes, fees, and financing cost. Return of capital is cash flow, not automatically profit. Dividend reinvestment is compounding, not financial leverage.

## Research material risks

For material positions or complex products, verify current facts using primary sources: issuer pages and prospectuses, SEC filings, fund reports, and official earnings releases. Browse because yields, distributions, leverage, fees, holdings, and company fundamentals change.

Pay special attention to:

- daily-reset leveraged and inverse ETFs, path dependence, and volatility decay;
- covered-call or option-income funds, upside caps, NAV erosion, distribution composition, and return of capital;
- mortgage REIT balance-sheet leverage and rate/spread sensitivity;
- single-stock concentration and earnings or regulatory dependence;
- overlapping indexes and duplicated factor exposure;
- borrowing cost, maintenance requirements, forced-liquidation risk, taxes, and FX exposure when the user uses actual debt.

## Evaluate against the objective

First identify whether the primary objective is spendable monthly income, dividend reinvestment, long-term growth, or debt-financed leverage. If unclear, analyze the current structure first and ask one concise question at the end rather than blocking useful work.

Judge whether each holding functions as core growth, diversified income, tactical leverage, or speculation. Highlight when the portfolio's actual risk drivers conflict with the stated objective. Do not recommend averaging down merely because a price fell.

## Exercise independent judgment

Treat the user's market view, preferred holding period, and proposed action as inputs or hypotheses, not as conclusions to endorse. Test them against the available evidence and a credible opposing case before recommending an action.

- Separate observed facts, the user's preference or thesis, and the final analytical judgment.
- State disagreement plainly when the evidence or portfolio objective points elsewhere; explain the deciding facts and tradeoff without manufacturing certainty.
- Do not mirror a user's confidence, fear, desire to avoid realizing a loss, or wish to wait for break-even. Cost basis is relevant to taxes and behavior, but it does not by itself improve expected future return.
- Before endorsing a hold-until-break-even plan, assess concentration, opportunity cost, product structure, thesis deterioration, tax effects, and the possibility that break-even never occurs.
- When evidence is mixed, give a conditional judgment with explicit monitoring or invalidation criteria instead of defaulting to the user's preferred answer.
- Preserve the user's risk tolerance and constraints when choosing an implementable pace, while keeping the recommended destination and risk assessment evidence-led.

## Deliver the review

Lead with the portfolio-level conclusion. Keep the output scan-friendly and include:

1. dated account snapshot and important data limitations;
2. concentration, loss drivers, income quality, leverage, overlap, and liquidity;
3. a concise position table with role, risk, and action category;
4. prioritized next actions, expressed as target ranges or review steps rather than false precision;
5. the one missing fact that would most change the recommendation.

Clearly separate observed data, calculated estimates, and judgment. Cite current external claims next to the relevant statement. Present analysis as decision support, not guaranteed outcomes or individualized tax advice.
