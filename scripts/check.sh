#!/usr/bin/env bash
# Runs every automated check: headless tests, formatting, Rojo build, and luau-lsp type analysis.
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p .cache
if [ ! -f .cache/globalTypes.d.luau ]; then
	curl -sSL -o .cache/globalTypes.d.luau \
		https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
fi

lune run tests/run
lune run scripts/export-strings .cache/Strings.csv > /dev/null
if ! cmp -s .cache/Strings.csv localization/Strings.csv; then
	echo "localization/Strings.csv is out of date: run 'lune run scripts/export-strings'"
	exit 1
fi
stylua --check src tests
rojo build -o .cache/check.rbxl > /dev/null
rojo sourcemap -o .cache/sourcemap.json > /dev/null
problems=$(luau-lsp analyze --definitions=.cache/globalTypes.d.luau --sourcemap=.cache/sourcemap.json src 2>&1 \
	| grep -v -E '^\[(INFO|WARN)\]' || true)
if [ -n "$problems" ]; then
	echo "$problems"
	echo "luau-lsp found problems"
	exit 1
fi
echo "All checks passed"
