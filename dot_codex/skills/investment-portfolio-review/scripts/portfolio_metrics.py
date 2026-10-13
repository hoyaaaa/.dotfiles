#!/usr/bin/env python3
"""Calculate portfolio weights and P/L contributions from normalized JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def load_payload(path: str | None) -> dict:
    if path:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    return json.load(sys.stdin)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", help="JSON file; omit to read stdin")
    args = parser.parse_args()
    payload = load_payload(args.path)
    positions = payload.get("positions", [])

    market_total = sum(float(p.get("market_value", 0)) for p in positions)
    cost_total = sum(float(p.get("cost_basis", 0)) for p in positions)
    unrealized_total = sum(
        float(p.get("unrealized_pl", float(p.get("market_value", 0)) - float(p.get("cost_basis", 0))))
        for p in positions
    )
    distributions_total = sum(float(p.get("distributions", 0)) for p in positions)
    cash = float(payload.get("cash", 0))
    account_total = market_total + cash

    rows = []
    for p in positions:
        market_value = float(p.get("market_value", 0))
        cost_basis = float(p.get("cost_basis", 0))
        unrealized_pl = float(p.get("unrealized_pl", market_value - cost_basis))
        distributions = float(p.get("distributions", 0))
        rows.append(
            {
                "symbol": p.get("symbol") or p.get("name"),
                "weight_pct": round(100 * market_value / market_total, 2) if market_total else None,
                "unrealized_pl": unrealized_pl,
                "loss_contribution_pct": round(100 * unrealized_pl / unrealized_total, 2)
                if unrealized_total
                else None,
                "total_return_amount": unrealized_pl + distributions,
                "total_return_pct": round(100 * (unrealized_pl + distributions) / cost_basis, 2)
                if cost_basis
                else None,
                "recovery_to_cost_pct": round(100 * (cost_basis / market_value - 1), 2)
                if market_value > 0 and cost_basis > market_value
                else 0.0,
            }
        )

    rows.sort(key=lambda row: row["weight_pct"] or 0, reverse=True)
    result = {
        "market_value": market_total,
        "cost_basis": cost_total,
        "unrealized_pl": unrealized_total,
        "distributions": distributions_total,
        "economic_pl_before_tax_and_financing": unrealized_total + distributions_total,
        "cash": cash,
        "cash_weight_pct": round(100 * cash / account_total, 2) if account_total else None,
        "top_1_weight_pct": rows[0]["weight_pct"] if rows else None,
        "top_2_weight_pct": round(sum((r["weight_pct"] or 0) for r in rows[:2]), 2),
        "positions": rows,
    }
    json.dump(result, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
