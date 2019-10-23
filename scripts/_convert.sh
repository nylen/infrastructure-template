#!/usr/bin/env bash

set -e

newname="$1"
if [ -z "$newname" ]; then
	echo "Usage: $0 NewName"
	exit 1
fi

newname_lower="$(echo "$newname" | tr '[A-Z]' '[a-z]')"
newname_upper="$(echo "$newname" | tr '[a-z]' '[A-Z]')"

cd "$(dirname "$0")"
cd ..

find . -not \( -path ./.git -prune \) -name '*project''name*' | while read i; do
	mv -v "$i" "$(echo "$i" | sed "s/project""name/$newname_lower/g")"
done

replace_text() {
	search="$1"
	replace="$2"

	find . -not \( -path ./.git -prune \) -type f \
		| xargs grep --files-with-match "$search" \
		| while read filename; do
			echo "edit: $filename" >&2
			sed -i "s/$search/$replace/g" "$filename"
		done
}

replace_text project''name "$newname_lower"
replace_text Project''Name "$newname"
replace_text PROJECT''NAME "$newname_upper"
