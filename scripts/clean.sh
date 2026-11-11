#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# ビルドやコンパイルで作ったものを削除する。
#
#   scripts/clean.sh          scripts/build.sh が作ったもの（$BUILD_DIR）を削除
#   scripts/clean.sh --elc    scripts/compile.sh が作った .elc を削除
#   scripts/clean.sh --all    両方を削除
#
# インストール済みのもの（scripts/install.sh）は削除しない。
# Bazel のキャッシュには書き込み禁止のファイルがあるので、先に Bazel に
# 片付けさせてから、書き込みを許可して削除する。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"

CLEAN_BUILD=1
CLEAN_ELC=0
case "${1:-}" in
  "")      ;;
  --elc)   CLEAN_BUILD=0; CLEAN_ELC=1 ;;
  --all)   CLEAN_ELC=1 ;;
  *)       echo "usage: $0 [--elc | --all]" >&2; exit 2 ;;
esac

if [ "$CLEAN_BUILD" = 1 ]; then
  if [ ! -d "$BUILD_DIR" ]; then
    echo "$BUILD_DIR はありません"
  else
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
  fi
fi

if [ "$CLEAN_ELC" = 1 ]; then
  echo "==> .elc を削除"
  find "$ROOT/tamago-tsunagi" "$ROOT/lisp" -name '*.elc' -print -delete | sed "s|^$ROOT/|  |"
fi

echo "完了"
