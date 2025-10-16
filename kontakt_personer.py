#!/usr/bin/env python3
import csv
from collections import defaultdict
from datetime import datetime
from math import pow
import statistics

ISO_FORMATS = [
    "%Y-%m-%dT%H:%M:%S%z",
    "%Y-%m-%d %H:%M:%S%z",
]


def parse_ts(s: str) -> datetime:
    for f in ISO_FORMATS:
        try:
            return datetime.strptime(s, f)
        except ValueError:
            continue
    raise ValueError(f"Unrecognized timestamp: {s}")


def read_csv(path: str):
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def compute_contribution_with_decay(rows, half_life_days: float, now: datetime):
    contribution_weight = defaultdict(lambda: defaultdict(float))  # repo -> author -> weight
    for r in rows:
        ts = parse_ts(r["timestamp"])
        age_days = max(0.0, (now - ts).total_seconds() / 86400.0)
        weight = pow(0.5, age_days / half_life_days) if half_life_days > 0 else 1.0
        size = int(r["lines_added"]) + int(r["lines_removed"])
        contribution_weight[r["repo"]][r["author"]] += size * weight
    return contribution_weight


def compute_author_normalizing(weights, alpha: float):
    # Aggregate global (cross-repo) weight per author
    # alpha is a tuning parameter, range 0..1, where 0 is no normalization
    global_contributions = defaultdict(float)
    for repo_weights in weights.values():
        for author, val in repo_weights.items():
            global_contributions[author] += val
    if not global_contributions:
        return {}
    vals = list(global_contributions.values())
    median_val = statistics.median(vals) or 1.0
    adjusted_down = {}
    for author, total in global_contributions.items():
        adjusted_down[author] = 1.0 / (1.0 + alpha * (total / median_val))
    return adjusted_down


def apply_normalization(weights, normalization_factor):
    adjusted = defaultdict(lambda: defaultdict(float))
    for repo, repo_scores in weights.items():
        for author, val in repo_scores.items():
            adjusted[repo][author] = val * normalization_factor.get(author, 1.0)
    return adjusted


def format_output(adjusted_scores, top_n: int):
    lines = []
    for repo in sorted(adjusted_scores.keys()):
        lines.append(f"Repo: {repo}")
        ranked = sorted(adjusted_scores[repo].items(), key=lambda x: x[1], reverse=True)[:top_n]
        for i, (author, score) in enumerate(ranked, 1):
            lines.append(f"  {author}")
    return "\n".join(lines)


def main():
    filename = "commits.csv"
    try:
        commits = read_csv(filename)
    except FileNotFoundError:
        print(f"File not found: {filename}")
        print("Run 'create_git_summary.py' first to generate the commits.csv file.")
        return

    if not commits:
        print("No rows found in", filename)
        return

    now = max(parse_ts(row["timestamp"]) for row in commits)

    base_weights = compute_contribution_with_decay(commits, 120, now)
    normalization_factors = compute_author_normalizing(base_weights, 0.5)
    adjusted = apply_normalization(base_weights, normalization_factors)

    print("Forslag til kontaktpersoner")
    print("--------------------------------")
    print(format_output(adjusted, 5))


if __name__ == "__main__":
    main()
