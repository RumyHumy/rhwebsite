#!/bin/bash

set -x

git pull
git add *
git commit -am "$1"
git push
