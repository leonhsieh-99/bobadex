#!/usr/bin/env bash
set -euo pipefail

readonly roots=(lib/pages lib/widgets)
readonly legacy_pattern='Constants\.getThemeColor|themeMap|AppButtonStyles|MaterialColor|themeColor\.shade'
readonly direct_color_pattern='Colors\.(?!transparent\b)'

if rg -n "$legacy_pattern" "${roots[@]}"; then
  echo "Legacy theme access found. Use context.boba tokens instead." >&2
  exit 1
fi

if rg --pcre2 -n "$direct_color_pattern" "${roots[@]}"; then
  echo "Direct Material colors found. Use semantic BobaTokens instead." >&2
  exit 1
fi
