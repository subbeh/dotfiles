#!/usr/bin/env bash
# Usage: review-items.sh <owner> <repo> <pr>
# Prints the PR's open bot review feedback as JSON: botThreads (unresolved
# inline threads opened by a bot), botNotes (top-level bot
# comments/reviews not yet marked with your 👀) and humanThreads (URLs only).
set -euo pipefail

gh api graphql -f owner="$1" -f repo="$2" -F pr="$3" -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        totalCount
        nodes {
          id isResolved isOutdated path line
          comments(first: 20) { nodes { author { login __typename } body url } }
        }
      }
      comments(last: 50) {
        nodes { id author { login __typename } body url reactionGroups { content viewerHasReacted } }
      }
      reviews(last: 50) {
        nodes { id state author { login __typename } body url reactionGroups { content viewerHasReacted } }
      }
    }
  }
}' --jq '
.data.repository.pullRequest as $p
| def bot: .author.__typename == "Bot";
  def seen: any(.reactionGroups[]?; .content == "EYES" and .viewerHasReacted);
  def open: $p.reviewThreads.nodes[] | select(.isResolved | not);
{
  threadsFetched: ($p.reviewThreads.nodes | length),
  threadsTotal: $p.reviewThreads.totalCount,
  botThreads: [open | select(.comments.nodes[0] | bot)
    | {id, path, line, isOutdated, url: .comments.nodes[0].url,
       comments: [.comments.nodes[] | {who: .author.login, body}]}],
  humanThreads: [open | select(.comments.nodes[0] | bot | not) | .comments.nodes[0].url],
  botNotes: [($p.comments.nodes[], ($p.reviews.nodes[] | select(.state != "APPROVED")))
    | select(bot and (seen | not) and (.body | length > 0)) | {id, url, body}]
}'
