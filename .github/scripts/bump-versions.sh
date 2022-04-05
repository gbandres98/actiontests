#!/bin/bash

after=${AFTER_COMMIT_SHA}
before=${BEFORE_COMMIT_SHA}

readarray -t version_files < .github/version_files

for commit in $(git rev-list --reverse $before..$after); do
    git checkout -q $commit
    commit_msg=$(git log -1 --pretty=format:"%s")
    changes=$(git diff --name-only HEAD^ HEAD)

    echo $commit_msg

    for version_file in "${version_files[@]}"; do
        version_file_dir=$(dirname $version_file)
        version_change_file=$version_file_dir/version_changelog

        for change in ${changes[@]}; do
            if echo $change | grep -q $version_file_dir; then

                # Commit bumps this version

                if echo $commit_msg | grep -qE '(!:)|BREAKING'; then
                    echo "MAJOR" > $version_change_file
                    break
                fi

                if echo $commit_msg | grep -qE '^feat'; then
                    if ! echo $(cat $version_change_file) | grep -qE 'MAJOR'; then
                        echo "MINOR" > $version_change_file
                    fi
                    break
                fi

                if ! echo $(cat $version_change_file) | grep -qE '(MAJOR)|(MINOR)'; then
                    echo "PATCH" > $version_change_file
                fi

            fi
        done
    done

done

git checkout main -q

for version_file in "${version_files[@]}"; do
    version_file_dir=$(dirname $version_file)
    version_change_file=$version_file_dir/version_changelog

    version=$(cat $version_file)
    version_change=$(cat $version_change_file)
    IFS=. eval 'read -ra sem_values <<< "$version"'

    echo $version_file
    echo $version
    echo $version_change

    if [[ $version_change == "MAJOR" ]]; then
        (( sem_values[0]++ ))
        sem_values[1]=0
        sem_values[2]=0
    fi

    if [[ $version_change == "MINOR" ]]; then
        (( sem_values[1]++ ))
        sem_values[2]=0
    fi

    if [[ $version_change == "PATCH" ]]; then
        (( sem_values[2]++ ))
    fi

    printf -v version '%s.' "${sem_values[@]}"
    version=$(sed 's/\.$//' <<< $version)

    echo $version
    echo $version > $version_file

    git add $version_file
done

git config --global user.name 'Squad 3 CI'
git config --global user.email 'squad3-ci@paack.co'

git commit -m "CI: Bump versions"
git push