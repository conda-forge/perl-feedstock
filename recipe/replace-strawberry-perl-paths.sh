#!/usr/bin/env bash
set -xeu

cd "${SRC_DIR}/perl"

find -type f -name .packlist -delete

rm './lib/perllocal.pod'
touch './lib/perllocal.pod'

STRAWBERRY_PREFIX='C:\strawberry\perl'
for pathsep in '/' '\' '\\' ; do
    _strawberry_prefix="${STRAWBERRY_PREFIX//\\/${pathsep//\\/\\\\}}"
    _library_prefix="${LIBRARY_PREFIX//\\/${pathsep//\\/\\\\}}"
    grep -rl "${_strawberry_prefix}" . \
        | while IFS= read -r file; do
            sed -i "s|${_strawberry_prefix}|${_library_prefix}|g" "$file"
          done
done