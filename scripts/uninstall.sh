#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# scripts/install.sh でインストールしたものを削除する。
#
#   scripts/uninstall.sh
#
# Mozc の学習データとユーザー辞書（~/Library/Application Support/Mozc/）は削除しない。

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
LIBEXEC="$PREFIX/libexec/egg-mozc"
LABEL="org.mozc.inputmethod.Japanese.Converter"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
if [ -f "$PLIST" ] && grep -q "$LIBEXEC/mozc_server" "$PLIST"; then
  /bin/rm -f "$PLIST"
  echo "削除: $PLIST"
elif [ -f "$PLIST" ]; then
  echo "そのままにしました（egg-mozc 以外のものを指しています）: $PLIST"
fi

for f in mozc_server mozc_emacs_helper mozc_user_dict mozc.el; do
  [ -e "$LIBEXEC/$f" ] && /bin/rm -f "$LIBEXEC/$f" && echo "削除: $LIBEXEC/$f"
done
rmdir "$LIBEXEC" 2>/dev/null || true

echo "完了。Mozc のデータ（~/Library/Application Support/Mozc/）は残しています。"
