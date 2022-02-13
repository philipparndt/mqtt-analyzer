#!/bin/bash
cd $(dirname $0)
set -e

cd ..
git apply -R ci/realm.patch