#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# scripts/build.sh でビルドしたものと Lisp 一式をインストールし、mozc_server を
# ユーザー単位の LaunchAgent として登録する。
#
#   $PREFIX/libexec/egg-mozc/                 mozc_server、mozc_emacs_helper、mozc_user_dict
#   $PREFIX/share/emacs/site-lisp/egg-mozc/   egg-mozc.el、egg/mozc.el、tamago-tsunagi/、mozc/mozc.el
#
# scripts/compile.sh で作った .elc があれば、それもコピーする（先に compile.sh を実行する）。
#
#   scripts/install.sh [--no-launchagent]
#
# 環境変数:
#   PREFIX     インストール先（既定: ~/.local）
#              実行ファイルは $PREFIX/libexec/egg-mozc/、Lisp は
#              $PREFIX/share/emacs/site-lisp/egg-mozc/ に入る
#   BUILD_DIR  scripts/build.sh の作業ディレクトリ（既定: <repo>/build）
#
# macOS 版の Mozc は、mozc_server を launchd 経由で起動し、launchd に登録した
# Mach サービスで通信する。そのため、mozc_server を LaunchAgent として登録する
# 必要がある（Mozc の IME 本体 Mozc.app はインストールしない）。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
PREFIX="${PREFIX:-$HOME/.local}"
LIBEXEC="$PREFIX/libexec/egg-mozc"
SITE_LISP="$PREFIX/share/emacs/site-lisp/egg-mozc"
LABEL="org.mozc.inputmethod.Japanese.Converter"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

LAUNCHAGENT=1
for arg in "$@"; do
  case "$arg" in
    --no-launchagent) LAUNCHAGENT=0 ;;
    *) echo "usage: $0 [--no-launchagent]" >&2; exit 2 ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }

for f in mozc_server mozc_emacs_helper mozc_user_dict; do
  [ -x "$BUILD_DIR/bin/$f" ] || die "$BUILD_DIR/bin/$f がありません。先に scripts/build.sh を実行してください"
done

if [ -d "/Library/Input Methods/Mozc.app" ]; then
  echo "warning: Mozc の IME（/Library/Input Methods/Mozc.app）がインストールされています。" >&2
  echo "         同じ名前の LaunchAgent を使うため、egg-mozc と同時には使えません。" >&2
fi

echo "==> $LIBEXEC にインストール"
mkdir -p "$LIBEXEC"
install -m 755 "$BUILD_DIR/bin/mozc_server" \
               "$BUILD_DIR/bin/mozc_emacs_helper" \
               "$BUILD_DIR/bin/mozc_user_dict" "$LIBEXEC/"
# 以前の版は mozc.el を libexec に入れていた
/bin/rm -f "$LIBEXEC/mozc.el"

echo "==> $SITE_LISP にインストール"
# 前回の版のファイルが残らないように、いったん消してから入れ直す
/bin/rm -rf "$SITE_LISP"
mkdir -p "$SITE_LISP/egg" "$SITE_LISP/mozc"
install -p -m 644 "$ROOT/lisp/egg-mozc.el" "$ROOT/LICENSE" "$SITE_LISP/"
install -p -m 644 "$ROOT/lisp/egg/mozc.el" "$SITE_LISP/egg/"
[ -f "$ROOT/lisp/egg-mozc.elc" ] && install -p -m 644 "$ROOT/lisp/egg-mozc.elc" "$SITE_LISP/"
[ -f "$ROOT/lisp/egg/mozc.elc" ] && install -p -m 644 "$ROOT/lisp/egg/mozc.elc" "$SITE_LISP/egg/"
cp -Rp "$ROOT/tamago-tsunagi" "$SITE_LISP/tamago-tsunagi"
if [ -f "$BUILD_DIR/bin/mozc.el" ]; then
  install -p -m 644 "$BUILD_DIR/bin/mozc.el" "$SITE_LISP/mozc/"
else
  echo "warning: $BUILD_DIR/bin/mozc.el がありません。MELPA の mozc パッケージなどを使ってください" >&2
fi

if [ "$LAUNCHAGENT" = 1 ]; then
  echo "==> LaunchAgent $LABEL を登録"
  mkdir -p "$(dirname "$PLIST")"
  sed "s|@MOZC_SERVER@|$LIBEXEC/mozc_server|" \
      "$ROOT/macos/$LABEL.plist.in" > "$PLIST.tmp"
  plutil -lint "$PLIST.tmp" >/dev/null
  # 登録済みなら一度外してから登録し直す（パスの変更を反映させるため）
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  mv "$PLIST.tmp" "$PLIST"
  launchctl bootstrap "$DOMAIN" "$PLIST"
  launchctl print "$DOMAIN/$LABEL" | grep -E "^\s*(state|program) =" || true
fi

cat <<EOF

完了。Emacs の初期化ファイルに次を追加してください:

  (add-to-list 'load-path "$SITE_LISP")
  (require 'egg-mozc)
  (setq default-input-method "japanese-egg-mozc")

helper の場所（${LIBEXEC}）と mozc.el は、egg-mozc が自動で見つけます。
MELPA の mozc パッケージを使う場合は、(require 'egg-mozc) の前に
(setq egg-mozc-mozc-el-directory nil) を書いてください。
EOF
