#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# scripts/build.sh が作ったもの（$BUILD_DIR）をすべて削除する。
#
#   scripts/clean.sh
#
# インストール済みのもの（scripts/install.sh）は削除しない。
# Bazel のキャッシュには書き込み禁止のファイルがあるので、先に Bazel に
# 片付けさせてから、書き込みを許可して削除する。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
[ -d "$BUILD_DIR" ] || { echo "$BUILD_DIR はありません"; exit 0; }
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"

if [ -d "$BUILD_DIR/mozc/src" ] && [ -d "$BUILD_DIR/bazel" ] && command -v bazelisk >/dev/null; then
  echo "==> Bazel のサーバーを止めて、キャッシュを片付ける"
  (
    cd "$BUILD_DIR/mozc/src"
    BAZELISK_HOME="$BUILD_DIR/bazelisk" \
      bazelisk --output_user_root="$BUILD_DIR/bazel" clean --expunge || true
    BAZELISK_HOME="$BUILD_DIR/bazelisk" \
      bazelisk --output_user_root="$BUILD_DIR/bazel" shutdown || true
  )
fi

echo "==> $BUILD_DIR を削除"
chmod -R u+w "$BUILD_DIR"
/bin/rm -rf "$BUILD_DIR"
echo "完了"
