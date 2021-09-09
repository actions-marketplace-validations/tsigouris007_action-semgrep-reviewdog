# Semgrep + Reviewdog Action

Use this Github action to scan your project using semgrep and receive annotations/comments using reviewdog.

## Parameters
### `tool_name`
Tool name to use for reviewdog reporter.
Default: `semgrep`
### `level`
Report level for reviewdog (info, warning, error).
Default: `warning`
### `reporter`
Reporter of reviewdog command (github-pr-check, github-pr-review).
Default: `github-pr-check`
### `filter_mode`
Filtering mode for the reviewdog command (added, diff_context, file, nofilter).
Default: `added`
### `fail_on_error`
Exit code for reviewdog when errors are found (true, false).
Default: `false`
Note: Final error is calculated by counting findings instead of reviewdog output.
### `reviewdog_flags`
Additional reviewdog flags.
Default: `nil`
### `semgrep_flags`
Semgrep flags.
Default: `--disable-verion-check --verbose --config=p/ci`
Note: This is a free field to add any flags, includes, exludes, etc. you just have to prepare it in a previous step.
### `semgrep_ignore`
Custom semgrep ignore fingerprint file. You must provide a URL of the raw file.
Default: `nil`
Note: This is a custom functionality that ignores semgrep fingerprints (these are custom too) and you have the ability to ignore specific ones. Your ignore file should look like:
```json
 {
   "ignored_warnings": [
     {
       "note": "This is a custom note 1",
       "fingerprint": "a4efd74060e37fae96be358e760d0404fe05c27d4a5acce8581277e84301fff5"
     },
     {
       "note": "This is a custom note 2",
       "fingerprint": "a29580bf83e78a27fcbc34fcf6295bf7fa0b5a6568f6f6ce4bfb67c65cfa7fab"
     }
   ]
 }
```
## Examples
```yml
name: Semgrep Action
on:
  pull_request:
    paths:
      - '*.js'
      - '*.jsx'
jobs:
  Semgrep:
    runs-on: self-hosted # Or ubuntu
    env:
    steps:
      - name: Checkout action
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: Fetch changes
        run: |
          CHANGED_FILES=$(git diff --name-only --diff-filter=ACMRT ${{github.event.pull_request.base.sha}} ${{github.sha}} | grep -E '*.js|*.jsx' | xargs)
          IFS=' ' tokens=($CHANGED_FILES)
          SCAN_FILES=$(echo "$CHANGED_FILES" | tr ' ' '\n' | sed 's/[^ ]* */--include=&/g' | tr '\n' ' ')
          echo "SCAN_FILES=$(echo $SCAN_FILES)" >> $GITHUB_ENV
      - name: Run semgrep
        uses: tsigouris007/action-semgrep-reviewdog@v[VERSION_NUMBER]
        with:
          github_token: ${{ secrets.github_token }}
          level: error
          reporter: github-pr-check
          filter_mode: nofilter
          semgrep_flags: "${{ env.SCAN_FILES }} --config=p/ci --disable-version-check"
          tool_name: Semgrep findings
          semgrep_ignore: "https://raw.github.com/repo/branch/semgrep.ignore"
```
