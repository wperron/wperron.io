#!/bin/bash
if ! hash showdown 2>/dev/null; then
  npm install -g showdown
fi

for f in $(find ./src/content -name "*.md"); do
  echo "parsing: $f"
  filename=$(basename $f)
  extension="${filename##*.}"
  filename="${filename%.*}"

  showdown makehtml -i $f -o ./public/pages/$filename.html
done