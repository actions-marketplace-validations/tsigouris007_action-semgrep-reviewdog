#!/bin/bash
export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Create a temp random file for semgrep output
RANDOM_FILE="$GITHUB_WORKSPACE/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1).json"

SEMGREP="semgrep ${INPUT_SEMGREP_FLAGS} -o $RANDOM_FILE --json $GITHUB_WORKSPACE"

echo "Running: $SEMGREP"
$SEMGREP

if [ -z "${INPUT_SEMGREP_IGNORE}" ]
then
  PARSE="ruby /parser.rb -f $RANDOM_FILE -r $GITHUB_WORKSPACE/"
else
  wget ${INPUT_SEMGREP_IGNORE} -O $GITHUB_WORKSPACE/semgrep.ignore
  PARSE="ruby /parser.rb -f $RANDOM_FILE -i $GITHUB_WORKSPACE/semgrep.ignore -r \"$GITHUB_WORKSPACE/\""
fi

# Display the output on screen for debugging reasons
$PARSE

# Filter with jq and pipe to reviewdog for annotations
$PARSE \
  | jq -r '.fingerprints[] | "\(.severity[0:1]);\(.file);\(.start_line);\(.warning_type) [\(.fingerprint)]"' \
  | reviewdog \
      -efm="%t;%f;%l;%m" \
      -name="${INPUT_TOOL_NAME}" \
      -reporter="${INPUT_REPORTER}" \
      -filter-mode="${INPUT_FILTER_MODE}" \
      -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
      -level="${INPUT_LEVEL}" \
      ${INPUT_REVIEWDOG_FLAGS}

WARNINGS="$(echo $($PARSE) | jq '.warnings')"

rm $RANDOM_FILE

exit $WARNINGS
