import argparse
import datetime
import os
import re
import subprocess
import sys

EXCLUDE_DIRS = {'.gradle', '.idea', 'build', '.git', 'node_modules', '.next'}

def find_git_repos(root_dir):
    depth0 = []
    for entry in os.scandir(root_dir):
        if entry.is_dir():
            git_dir = os.path.join(entry.path, '.git')
            if os.path.isdir(git_dir):
                depth0.append(entry.path)
    depth1 = []
    for entry in os.scandir(root_dir):
        if entry.is_dir():
            for subentry in os.scandir(entry.path):
                if subentry.is_dir():
                    git_dir = os.path.join(subentry.path, '.git')
                    if os.path.isdir(git_dir):
                        depth1.append(subentry.path)
    if depth1:
        return depth1
    return depth0

def find_kt_files(repo_path):
    for root, dirs, files in os.walk(repo_path):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]
        for file in files:
            if file.lower().endswith('.kt'):
                yield os.path.join(root, file)

def is_tracked_by_git(repo_path, rel_path):
    result = subprocess.run(
        ['git', 'ls-files', '--error-unmatch', rel_path],
        cwd=repo_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    return result.returncode == 0

def get_first_commit_date(repo_path, rel_path, line_number):
    result = subprocess.run(
        ['git', 'log', '-L', f'{line_number},{line_number}:{rel_path}', '--date=iso'],
        cwd=repo_path,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    if result.returncode != 0:
        return None
    dates = re.findall(r'Date:\s+(\d{4}-\d{2}-\d{2})', result.stdout)
    if not dates:
        return None
    return min(datetime.datetime.strptime(d, '%Y-%m-%d') for d in dates)

def collect_deprecated_lines(repo_path, file_path, cutoff_date):
    rel_path = os.path.relpath(file_path, repo_path)
    if not is_tracked_by_git(repo_path, rel_path):
        return []
    results = []
    with open(file_path, 'r') as f:
        for idx, line in enumerate(f, 1):
            if '@Deprecated' in line:
                commit_date = get_first_commit_date(repo_path, rel_path, idx)
                if commit_date and commit_date < cutoff_date:
                    results.append((commit_date, file_path, idx, line.strip()))
    return results

def truncate_deprecated_line(line):
    idx = line.find('@Deprecated')
    if idx == -1:
        return line
    after = line[idx + len('@Deprecated'):]
    truncate_at = 25
    after = after[:truncate_at] + ('...' if len(after) > truncate_at else '')
    return line[:idx + len('@Deprecated')] + after

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Find oldest @Deprecated lines in Kotlin files.\n"
                    f"Usage: python {sys.argv[0]} [DAYS_AGO]",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument('days_ago', type=int, nargs='?', default=90, help='Number of days ago to use as cutoff (default: 180)')

    args = parser.parse_args()

    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=args.days_ago)
    repos = find_git_repos('.')
    print(f"Scanning {len(repos)} repositories for @Deprecated lines older than {args.days_ago} days:\n")

    all_deprecations = []
    for repo in repos:
        for kt_file in find_kt_files(repo):
            all_deprecations.extend(collect_deprecated_lines(repo, kt_file, cutoff_date))
    all_deprecations.sort(key=lambda x: x[0])
    print(f"@Deprecated lines older than {args.days_ago} days:\n")
    for entry in all_deprecations:
        date, file_path, idx, line = entry
        print(f"{date.date()} {file_path}:{idx} - {truncate_deprecated_line(line)}")
    print(f"\nTotal found: {len(all_deprecations)}")
