#!/bin/bash
set -eu # Increase bash strictness
shopt -s globstar # Enable globstar

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

export REVIEWDOG_VERSION=v0.14.1

echo "[action-pylint] Installing reviewdog..."
wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b /tmp "${REVIEWDOG_VERSION}"

if [[ "$(which pylint)" == "" ]]; then
  echo "[action-pylint] Installing pylint package..."
  python -m pip install --upgrade pylint
fi
echo "[action-pylint] pylint version:"
pylint --version

rcfile_option=""
if [[ "$INPUT_PYLINT_RC" != "" ]]; then
  rcfile_option="--rcfile=${INPUT_PYLINT_RC}"
fi

echo "[action-pylint] Checking python code with the pylint linter and reviewdog..."
exit_val="0"

pylint --score n ${rcfile_option} ${INPUT_PYLINT_ARGS} ${INPUT_GLOB_PATTERN} 2>&1 | # Removes ansi codes see https://github.com/reviewdog/errorformat/issues/51
  /tmp/reviewdog -efm="%f:%l:%c: %m" \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
    -level="${INPUT_LEVEL}" \
    ${INPUT_REVIEWDOG_FLAGS} || exit_val="$?"

echo "[action-pylint] Clean up reviewdog..."
rm /tmp/reviewdog

if [[ "${exit_val}" -ne '0' ]]; then
  exit 1
fi
