#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

for script in scripts/*.sh tests/*.sh; do
  bash -n "$script"
done
python3 -m py_compile scripts/*.py tests/*.py

python3 tests/test-device-catalog.py
bash tests/test-build-feature-bundle-regressions.sh
bash tests/test-prepare-release-assets.sh
bash tests/test-verify-build-output.sh

# Ruby/Psych is preinstalled on GitHub's Ubuntu runner.  PyYAML is the local
# fallback used by the Codex validation environment.
if command -v ruby >/dev/null 2>&1; then
  ruby -e '
    require "yaml"
    Dir[".github/workflows/*.{yml,yaml}"].sort.each do |path|
      YAML.load_file(path, aliases: true)
      puts "Workflow YAML passed: #{path}"
    end
  '
else
  python3 - <<'PY'
import pathlib
import yaml

for path in sorted(pathlib.Path(".github/workflows").glob("*.yml")):
    yaml.safe_load(path.read_text(encoding="utf-8"))
    print(f"Workflow YAML passed: {path}")
PY
fi

echo 'Repository validation passed.'
