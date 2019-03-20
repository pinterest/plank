#!/bin/bash

set -eou pipefail

update_current_line() {
    printf "\033[1A"  # move cursor one line up
    printf "\033[K"   # delete till end of line
    echo "$1"
}

plank_bin=.build/debug/plank
json_files=$( find Examples/PDK -name "*.json" )
lang_options=( "objc" "flow" "java" )
for lang in ${lang_options[@]}; do
  echo "[${lang}] Testing stability of generated output"
  lang_output_dir="$(mktemp -d)"
  echo "[${lang}] Generate control models for comparison"
  $plank_bin --lang ${lang} --output_dir=${lang_output_dir} ${json_files}
  echo "[${lang}] Testing output is stable" 
  for i in $(seq 100); do
    update_current_line "[${lang}] Testing output is stable (test case ${i}/100)" 
    treatment_lang_output_dir="$(mktemp -d)"
    $plank_bin --lang ${lang} --output_dir=${treatment_lang_output_dir} ${json_files}
    if ! diff -r "${lang_output_dir}" "${treatment_lang_output_dir}"; then
      update_current_line "[${lang}] ❌ Output is unstable"
      exit 1
    fi
  done
  update_current_line "[${lang}] ✅ Output is stable"
done
