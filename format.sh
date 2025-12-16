#!/bin/bash
set -e
if [ -n "$DEBUG$RUNNER_DEBUG" ] || [ $GITHUB_RUN_ATTEMPT != 1 ]; then
  set -x
fi

is_number() {
  [ "$1" -eq "$1" ] 2>/dev/null
}

job_count="${PARALLEL_TASKS}"
if [ -z "$job_count" ]; then
  job_count=$(nproc 2>/dev/null || sysctl -n hw.physicalcpu)
fi
if ! is_number "$job_count" || [ $job_count -lt 2 ]; then
  job_count=1
fi

if [ -z "$FILES" ] && [ ! -s "$LIST" ]; then
  echo "No files configured" >&2
  exit 1
fi

export NO_PROBLEMS=$(mktemp)
export PROBLEM_FILES_DIR=$(mktemp -d)

(
for file in $FILES; do
  printf "$file\0"
done

if [ -n "$LIST" ]; then
  cat "$LIST"
fi
) | xargs -P ${job_count} -0 -n1 $GITHUB_ACTION_PATH/indent-hocon.pl

: Report
files=$(mktemp)
git ls-files -m > "$files"
file_size=$(stat -c %s "$files")
if [ $file_size = 0 ]; then
  exit 0
fi
if [ -z "$SKIP_SUMMARY" ]; then
  diff=$(mktemp)
  git diff > "$diff"
  (
    echo '# hocon format'
    if [ $file_size -gt 1000000000 ]; then
      echo "Diff is too big, please check the artifact instead"
    else
      echo '```diff'
      cat "$diff"
      echo '```'
    fi
  ) | tee -a "$GITHUB_STEP_SUMMARY"
fi

marker=$(shasum "$files")
hash=$(echo "$marker$MATRIX" | shasum -)
(
  echo "id=${hash%% *}"
  echo "files<<$marker"
  cat "$files"
  echo "$marker"
) >> "$GITHUB_OUTPUT"
