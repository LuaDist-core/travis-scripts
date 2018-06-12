#!/usr/bin/env bash

# print all the executed commands and  exit if an error occurs
set -xe

PKG_DIR="$PWD"
REPORT_FILE="$PKG_DIR/../_luadist_install/*.md"

LUADIST_DIR="$PKG_DIR/../_luadist_bootstrap/_install"
TRAVIS_SCRIPTS_DIR="$PKG_DIR/../_travis_scripts"

export PKG_NAME="`basename $PKG_DIR`"
export PKG_OUTPUT_DIR="$PKG_DIR/../_luadist_output"
export LUA_BIN="$LUADIST_DIR/bin/lua"
export LUADIST_LIB="$LUADIST_DIR/lib/lua/luadist.lua"

REPORT_REPO="github.com/LuaDist-core/report-web"
export CLONED_REPO="$PKG_DIR/../_luadist_packages_web"

git config --global user.email "travis@travis-ci.org"
git config --global user.name "Travis CI"
git clone "https://$REPORT_REPO" "$CLONED_REPO"

export LUA_PATH="$TRAVIS_SCRIPTS_DIR/?.lua;;"
$LUA_BIN $TRAVIS_SCRIPTS_DIR/prepare_reports.lua

cd "$CLONED_REPO"

git add --all
git commit -m "${PKG_NAME} Linux reports"
git remote add origin_key https://${GITHUB_ACCESS_TOKEN}@$REPORT_REPO

until git push origin_key master
do
	git reset HEAD^
	git pull origin_key master
	git add --all
	git commit -m "${PKG_NAME} Linux reports"
done

