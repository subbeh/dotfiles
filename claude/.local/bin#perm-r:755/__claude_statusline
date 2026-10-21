#!/usr/bin/env bash
# Claude Code status line, styled to match the starship prompt defined in
# ~/.config/starship/config.toml: the same directory icon substitutions in
# bold bright-blue, a bold purple ❯ separator, and secondary info in dimmed
# white like starship's right_format.

input=$(cat)

# One jq call, \x1f-delimited. Not tab/space: bash `read` collapses runs of IFS
# whitespace regardless of IFS, so an empty field would shift every later field
# left by one. \x1f is not IFS whitespace, so empty fields survive.
IFS=$'\x1f' read -r cwd model model_id in_tok out_tok win cost \
  five_h seven_d < <(
  jq -r '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.model.id // ""),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 0),
    (.cost.total_cost_usd // 0),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  ] | map(tostring) | join("")' <<<"$input"
)

blue=$'\033[1;94m'
cyan=$'\033[1;36m'
green=$'\033[32m'
dim=$'\033[2;37m'
purple=$'\033[1;35m'
red=$'\033[1;31m'
yellow=$'\033[1;33m'
reset=$'\033[0m'

# Mirror the [directory].substitutions table from config.toml. '#' is the sed
# delimiter rather than '|', which would clash with the alternation in
# (/data|/Users/Shared/data) and abort with "parentheses not balanced".
#
# Order matters and matches starship: the ~/.config rules run before the bare
# ~/ rule, so once a prefix is rewritten the later rules no longer match.
path=${cwd/#$HOME/\~}
path=$(sed -E \
  -e 's#^~/\.config$#[]#' \
  -e 's#^~/\.config/#[] #' \
  -e 's#^~$#[]#' \
  -e 's#^~/#[] #' \
  -e 's#^(/data|/Users/Shared/data)#<data>#' \
  -e 's#^<data>/workspace/dotfiles$#[󰇘]#' \
  -e 's#^<data>/workspace/dotfiles/#[󰇘] #' \
  -e 's#^<data>/workspace$#[󱧽]#' \
  -e 's#^<data>/workspace/#[󱧽] #' \
  -e 's#^<data>$#[]#' \
  -e 's#^<data>/#[] #' <<<"$path")

# Context: meter input+output against the window. Claude Code can report a 200k
# window for a native-1M model whose provider path is not flagged for 1M (this
# account's id carries a [1m] suffix), which would peg the meter at 100% while
# the session happily continues -- so trust the suffix over the reported size.
total=$(( ${in_tok:-0} + ${out_tok:-0} ))
eff_win=${win:-0}
(( eff_win <= 0 )) && eff_win=200000
[[ $model_id == *"[1m]"* || $model_id == *"[1M]"* ]] && (( eff_win < 1000000 )) && eff_win=1000000
pct=$(awk -v t="$total" -v w="$eff_win" \
  'BEGIN{p=int(t/w*100+0.5); if(p>100)p=100; if(p<0)p=0; print p}')

# --no-optional-locks keeps a status line render from taking the index lock and
# fighting with an interactive git command in the same repo. The empty guard
# matters because `git -C ""` silently falls back to the process cwd, which would
# report an unrelated repo's branch.
branch=""
if [[ -n $cwd ]]; then
  branch=$(git --no-optional-locks -C "$cwd" branch --show-current 2>/dev/null)
fi

# Profile from the config dir this script is deployed into (~/.claude.<profile>).
profile=$(basename "$(dirname "$0")")
profile=${profile#.claude}
profile=${profile#.}
case $profile in
  work) profile_color=$red ;;
  personal) profile_color=$blue ;;
  *) profile_color=$yellow ;;
esac

# Usage: a subscription (Max) reports its 5h/7d rate-limit windows, which make
# the list-price cost meaningless; API billing (Bedrock) has no windows, so the
# cost is the usage figure. The windows only arrive after the first response.
usage=""
[[ -n $five_h ]] && usage+=" 5h $(printf '%.0f' "$five_h")%"
[[ -n $seven_d ]] && usage+=" 7d $(printf '%.0f' "$seven_d")%"

out=""
[[ -n $profile ]] && out+="${profile_color}${profile}${reset} "
out+="${blue}${path}${reset} ${purple}❯${reset}"
[[ -n $model ]] && out+=" ${dim}${model}${reset}"
(( total > 0 )) && out+=" ${dim}• $((total / 1000))k (${pct}%)${reset}"
if [[ -n $usage ]]; then
  out+=" ${dim}•${usage}${reset}"
elif [[ -n $cost ]]; then
  out+=" ${green}\$$(printf '%.2f' "$cost")${reset}"
fi
[[ -n $branch ]] && out+="  ${cyan}${reset} ${dim}${branch}${reset}"

printf '%s\n' "$out"
