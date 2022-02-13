#!/bin/bash
cd $(dirname $0)
set -e

cd ..
git apply ci/realm.patch