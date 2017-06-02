#!/bin/bash

cd $(echo $0 | sed 's#/[^/]*$##')

git pull > /tmp/load_portes_etroites.tmp 2>&1

./scrap.sh >> /tmp/load_portes_etroites.tmp 2>&1

if git status | grep "data/" > /dev/null; then
  cat /tmp/load_portes_etroites.tmp
  git add documents data
  git commit -m "autoupdate"
  git push
fi
