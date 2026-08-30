#!/usr/bin/env sh
# Agnosticity gate: principle docs (everything outside bindings/) must not name a stack, tool, or project.
# Extra project-specific terms (names of the codebase these docs were extracted from) go in the
# gitignored file check.local next to this script, one extended-regex alternation per line.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$here/skills/design-principles"
stack='laravel|eloquent|\bphp\b|\bpest\b|phpunit|artisan|inertia|\bvue\b|spatie|composer\.json|ServiceProvider|PHPArkitect|\bapp/|App\\\\|django|fastapi|\brails\b|nestjs|spring boot|findOrFail|firstOrFail|firstOrCreate|updateOrCreate|PropsData|\bprops\b'
project='this repo|in this codebase|this is us|\bour (team|codebase|product|company)\b|20[0-9]{2}-[0-9]{2}|\+45 ?[0-9]|\bdkk\b|\bkr\.|\bcvr\b|mitid|competition|gamification'
if [ -f "$here/check.local" ]; then
  while read -r line; do
    case "$line" in ''|'#'*) continue;; esac
    project="$project|$line"
  done < "$here/check.local"
fi
fail=0
hits=$(grep -rniE "$stack" "$root" --include='*.md' | grep -v '/bindings/' | grep -viE 'bindings/laravel|the laravel one|Bindings exist today|Detect the stack')
[ -n "$hits" ] && { echo "STACK-COUPLED lines outside bindings/:"; echo "$hits"; fail=1; }
hits=$(grep -rniE "$project" "$root" --include='*.md')
[ -n "$hits" ] && { echo "PROJECT-SPECIFIC lines:"; echo "$hits"; fail=1; }
# Broken relative markdown links
broken=$(find "$root" -name '*.md' | while read -r f; do
  grep -oE '\]\(([^)#]+)(#[^)]*)?\)' "$f" | sed -E 's/^\]\(//;s/\)$//;s/#.*//' | grep -vE '^(https?:|mailto:|$)' | while read -r l; do
    [ -e "$(dirname "$f")/$l" ] || echo "$f -> $l"
  done
done)
[ -n "$broken" ] && { echo "BROKEN LINKS:"; echo "$broken"; fail=1; }
# Backticked `some-doc-name.md` (hyphenated, i.e. a real doc name rather than an illustrative `index.md`) that exists nowhere in the skill — a dangling cross-reference
dangling=$(grep -rnoE '`[A-Za-z0-9_./]*[a-z]+-[A-Za-z0-9_./-]+\.md`' "$root" --include='*.md' | while IFS=: read -r f n ref; do
  name=$(basename "$(echo "$ref" | tr -d '`')")
  [ -n "$(find "$root" -name "$name" -print -quit)" ] || echo "$f:$n $ref"
done)
[ -n "$dangling" ] && { echo "DANGLING DOC REFERENCES:"; echo "$dangling"; fail=1; }
[ $fail -eq 0 ] && echo "OK: agnostic, no project refs, links resolve"
exit $fail
