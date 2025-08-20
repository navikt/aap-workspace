for repo in */.git; do
  REPO_DIR=$(dirname "$repo")
  # Get latest commit date as Unix timestamp and formatted date
  TIMESTAMP=$(git -C "$REPO_DIR" log -1 --format="%ct")
  FORMATTED_DATE=$(git -C "$REPO_DIR" log -1 --format="%cd" --date=iso)
  echo "$TIMESTAMP|$REPO_DIR|$FORMATTED_DATE"
done | sort -t'|' -k1,1nr | awk -F'|' '{print $2 " - " $3}'
