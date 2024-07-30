#!/bin/bash

apk add --no-cache  curl gettext inotify-tools;

templatedRulesPath=$TEMPLATED_RULES_PATH
renderedRulesPath=$RENDERED_RULES_PATH
shellFormat=$SHELL_FORMAT

substituteENV() {
    echo "substituting the values of environment variables in rules..."
    find "$templatedRulesPath" -type f | while read -r file; do
        envsubst "$shellFormat" < "$file" > "$renderedRulesPath/$(basename "$file")";
    done;
}

# do initial ENV substituting
substituteENV

# on projected module changes, kube creates new dir "..yyyy_mm_dd_xxx"
# and then moves symlinked dir "..data" to that and deletes old dir
# we will monitor 'DELETE,ISDIR' event of ..yyyy_mm_dd_xxx" delete
# since its the last step in sync files operation
# eg events sequence..
#     /var/thanos/rule-templates/ CREATE,ISDIR ..2024_07_29_13_28_59.2700877023
#     /var/thanos/rule-templates/ CREATE ..data_tmp
#     /var/thanos/rule-templates/ MOVED_FROM ..data_tmp
#     /var/thanos/rule-templates/ MOVED_TO ..data
#     /var/thanos/rule-templates/ DELETE test1.yaml
#     /var/thanos/rule-templates/ DELETE,ISDIR ..2024_07_29_13_27_29.567810463

echo "starting rules-watcher...";
inotifywait -m -e delete --format '%e %w %f' "$templatedRulesPath" |\
while read -r event path name; do
    echo "processing... $event $path $name";
    if [[ "$event" != "DELETE,ISDIR" || ! "$name" =~ ^\.{2}.+\.[[:digit:]]+$ ]]; then
    continue
    fi

    # clear old rendered rules 
    # (needed as some old files might be removed)
    rm -f "$renderedRulesPath"/*
    
    substituteENV

    echo "triggering thanos rule reload..."
    if [[ $(curl -s -w "%{http_code}" -X POST localhost:10902/-/reload) != 200 ]]; then 
    echo "error reloading alert rules"
    fi
done;
echo "error rules-watcher stopped";