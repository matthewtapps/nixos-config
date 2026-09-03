usage() {
  cat <<'EOF'
Usage: mr-rebase (--mine | --author USER | --all) [options]

Rebases every open merge request that matches the filter. Merge requests with
conflicts, and those already level with their target, are left alone.

Filters, one is required:
  --mine                Merge requests you authored.
  --author USER         Merge requests authored by USER.
  --all                 Every open merge request, whoever wrote it. Lists them
                        and asks first, unless you pass --yes.

Options:
  -R, --repo PATH       Project path, such as group/project. Defaults to
                        $MR_REBASE_PROJECT, then to the origin remote of the
                        current directory.
      --host HOST       GitLab host. Defaults to $GITLAB_HOST, then to the
                        origin remote when the project came from it, then to
                        $MR_REBASE_HOST.
      --target BRANCH   Only merge requests targeting BRANCH.
      --skip-ci         Rebase without starting a pipeline.
  -n, --dry-run         List what would be rebased, then stop.
  -y, --yes             Skip the --all confirmation.
  -h, --help            Show this help.
EOF
}

mine=0
all=0
author=""
target=""
repo="${MR_REBASE_PROJECT:-}"
host="${GITLAB_HOST:-}"
dry_run=0
skip_ci=0
assume_yes=0

needs_value() {
  echo "mr-rebase: $1 needs a value" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --mine) mine=1 ;;
    --all) all=1 ;;
    --author) [ $# -ge 2 ] || needs_value --author; author=$2; shift ;;
    --author=*) author=${1#*=} ;;
    --target) [ $# -ge 2 ] || needs_value --target; target=$2; shift ;;
    --target=*) target=${1#*=} ;;
    -R | --repo) [ $# -ge 2 ] || needs_value --repo; repo=$2; shift ;;
    --repo=*) repo=${1#*=} ;;
    --host) [ $# -ge 2 ] || needs_value --host; host=$2; shift ;;
    --host=*) host=${1#*=} ;;
    --skip-ci) skip_ci=1 ;;
    -n | --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "mr-rebase: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$all" -eq 1 ] && { [ "$mine" -eq 1 ] || [ -n "$author" ]; }; then
  echo "mr-rebase: --all cannot be combined with --mine or --author" >&2
  exit 2
fi

if [ "$mine" -eq 1 ] && [ -n "$author" ]; then
  echo "mr-rebase: --mine cannot be combined with --author" >&2
  exit 2
fi

if [ "$all" -eq 0 ] && [ "$mine" -eq 0 ] && [ -z "$author" ]; then
  echo "mr-rebase: no filter given, so this would rebase everyone's branches." >&2
  echo "Pass --mine, --author USER, or --all to include everyone's." >&2
  exit 2
fi

if [ -z "$repo" ]; then
  url=$(git config --get remote.origin.url 2>/dev/null || true)
  if [ -z "$url" ]; then
    echo "mr-rebase: no project given, and $PWD has no origin remote" >&2
    exit 2
  fi
  rest=${url#*://}
  rest=${rest#*@}
  case "$rest" in
    *:*) derived_host=${rest%%:*}; repo=${rest#*:} ;;
    *) derived_host=${rest%%/*}; repo=${rest#*/} ;;
  esac
  repo=${repo%.git}
  # Only a project taken from this remote shares its host. A project named on
  # the command line is unrelated to whatever repository you happen to be in.
  if [ -z "$host" ]; then
    host=$derived_host
  fi
fi

if [ -z "$host" ]; then
  host="${MR_REBASE_HOST:-}"
fi

if [ -z "$host" ]; then
  echo "mr-rebase: no host given, and none could be worked out." >&2
  echo "Pass --host, or set GITLAB_HOST." >&2
  exit 2
fi

project=${repo//\//%2F}

api=(glab api --hostname "$host")

auth_hint() {
  echo "mr-rebase: $1 on $host." >&2
  echo "Check your login: glab auth status --hostname $host" >&2
  exit 1
}

if [ "$mine" -eq 1 ]; then
  author=$("${api[@]}" user | jq -r '.username') || auth_hint "could not read your username"
fi

query="state=opened&per_page=100"
if [ -n "$author" ]; then
  query="$query&author_username=$author"
fi
if [ -n "$target" ]; then
  query="$query&target_branch=$target"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

"${api[@]}" --paginate "projects/$project/merge_requests?$query" >"$work/list.json" ||
  auth_hint "could not list merge requests for $repo"

mapfile -t iids < <(jq -r '.[].iid' "$work/list.json")

if [ "${#iids[@]}" -eq 0 ]; then
  echo "mr-rebase: no open merge requests match in $repo on $host"
  exit 0
fi

printf '%s merge request(s) in %s on %s:\n' "${#iids[@]}" "$repo" "$host"
jq -r '.[] | "  !\(.iid)  \(.author.username)  \(.title)"' "$work/list.json"

if [ "$dry_run" -eq 1 ]; then
  exit 0
fi

if [ "$all" -eq 1 ] && [ "$assume_yes" -eq 0 ]; then
  if [ ! -t 0 ]; then
    echo "mr-rebase: --all needs --yes when standard input is not a terminal" >&2
    exit 2
  fi
  read -r -p "Rebase all of these, including other people's? [y/N] " reply
  case "$reply" in
    y | Y | yes | Yes) ;;
    *) echo "aborted"; exit 1 ;;
  esac
fi

echo

detail() {
  "${api[@]}" "projects/$project/merge_requests/$1?include_rebase_in_progress=true&include_diverged_commits_count=true"
}

rebased=0
skipped=0
failed=0

for iid in "${iids[@]}"; do
  detail "$iid" >"$work/mr.json"
  title=$(jq -r '.title' "$work/mr.json")

  if [ "$(jq -r '.has_conflicts // false' "$work/mr.json")" = true ]; then
    printf '!%s skipped, conflicts: %s\n' "$iid" "$title"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$(jq -r '.rebase_in_progress // false' "$work/mr.json")" = true ]; then
    printf '!%s skipped, already rebasing: %s\n' "$iid" "$title"
    skipped=$((skipped + 1))
    continue
  fi

  # Rebasing a merge request that is level with its target changes nothing and
  # starts a pipeline for nothing.
  if [ "$(jq -r '.diverged_commits_count // -1' "$work/mr.json")" = 0 ]; then
    printf '!%s skipped, up to date: %s\n' "$iid" "$title"
    skipped=$((skipped + 1))
    continue
  fi

  rebase_path="projects/$project/merge_requests/$iid/rebase"
  if [ "$skip_ci" -eq 1 ]; then
    rebase_path="$rebase_path?skip_ci=true"
  fi

  if ! "${api[@]}" -X PUT "$rebase_path" >/dev/null; then
    printf '!%s failed to start: %s\n' "$iid" "$title"
    failed=$((failed + 1))
    continue
  fi

  # GitLab queues the rebase as a background job, so the outcome only appears on
  # a later read of the merge request.
  outcome=timeout
  for _ in $(seq 1 30); do
    sleep 2
    detail "$iid" >"$work/mr.json"
    if [ "$(jq -r '.rebase_in_progress // false' "$work/mr.json")" = false ]; then
      error=$(jq -r '.merge_error // ""' "$work/mr.json")
      if [ -n "$error" ]; then
        outcome=$error
      else
        outcome=ok
      fi
      break
    fi
  done

  case "$outcome" in
    ok)
      printf '!%s rebased: %s\n' "$iid" "$title"
      rebased=$((rebased + 1))
      ;;
    timeout)
      printf '!%s still running after 60 seconds: %s\n' "$iid" "$title"
      skipped=$((skipped + 1))
      ;;
    *)
      printf '!%s failed (%s): %s\n' "$iid" "$outcome" "$title"
      failed=$((failed + 1))
      ;;
  esac
done

printf '\n%s rebased, %s skipped, %s failed\n' "$rebased" "$skipped" "$failed"
[ "$failed" -eq 0 ]
