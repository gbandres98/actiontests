#!/bin/bash

regex1='^((feat)|(chore)|(fix)|(docs)|(refactor))(\(.+\))?!?: .+$'

readarray -t commits < <(jq -r '.[].commit.message' commits.json)

for commit in "${commits[@]}"
do
    if echo $commit | grep -qE "$regex1" ; then
        continue
    else
        echo $commit
        echo "Wrong commit format, please follow the commit formatting defined in the README"
        exit 1
    fi
done