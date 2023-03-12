#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 default.md new-file.md" >&2
  exit 1
fi

default_file="$1"
new_file="$2"

if [ ! -f "$default_file" ]; then
  echo "Error: default file '$default_file' does not exist" >&2
  exit 1
fi

if [ ! -f "$new_file" ]; then
  echo "Error: new file '$new_file' does not exist" >&2
  exit 1
fi

default_front_matter=$(awk '/^---/{p=1}; p; /^---/{p=0}' "$default_file")
new_front_matter=$(awk '/^---/{p=1}; p; /^---/{p=0}' "$new_file")

merged_front_matter=$(echo "$default_front_matter" | awk -v nfm="$new_front_matter" '
BEGIN{
  split(nfm,nfm_lines,"\n");
  for (i in nfm_lines){
    if (nfm_lines[i] ~ /^[a-zA-Z]+:/){
      split(nfm_lines[i], nfm_key_val, ": ");
      nfm_keys[nfm_key_val[1]] = nfm_key_val[2];
    }
  }
}
{
  if ($0 ~ /^[a-zA-Z]+:/){
    split($0, dfm_key_val, ": ");
    if (dfm_key_val[1] in nfm_keys){
      $0 = dfm_key_val[1] ": " nfm_keys[dfm_key_val[1]];
      delete nfm_keys[dfm_key_val[1]];
    }
  }
  print;
}
END{
  for (key in nfm_keys){
    print key ": " nfm_keys[key];
  }
}')

# Replace the front matter in new-file.md with the merged front matter
sed -i '/^---/{
  r <(echo "$merged_front_matter")
  d
}' "$new_file"

