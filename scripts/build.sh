#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# Mozc を取得して、mozc_server、mozc_emacs_helper、mozc_user_dict をビルドする。
#
#   scripts/build.sh
#
# 環境変数:
#   BUILD_DIR    作業ディレクトリ（既定: <repo>/build）
#   MOZC_COMMIT  ビルドする Mozc のコミット（既定: scripts/mozc-commit の内容）
#   MOZC_REPO    Mozc のリポジトリ（既定: https://github.com/google/mozc.git）
#
# 出力: $BUILD_DIR/bin/ に3つの実行ファイルができる。
#
# ダウンロードやキャッシュも、すべて $BUILD_DIR の下に作る（~/Library/Caches は使わない）。
#   $BUILD_DIR/mozc/      Mozc のソース
#   $BUILD_DIR/bazelisk/  Bazel 本体（Bazelisk がダウンロードしたもの）
#   $BUILD_DIR/bazel/     依存ライブラリのダウンロード、ビルド途中の生成物
#   $BUILD_DIR/bin/       できた実行ファイル
# 片付けるときは scripts/clean.sh を使う（$BUILD_DIR/bazel/ には書き込み禁止の
# ファイルがあり、そのままでは rm -rf で消せないため）。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
mkdir -p "$BUILD_DIR"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
MOZC_COMMIT="${MOZC_COMMIT:-$(tr -d '[:space:]' < "$ROOT/scripts/mozc-commit")}"
MOZC_REPO="${MOZC_REPO:-https://github.com/google/mozc.git}"
MOZC_DIR="$BUILD_DIR/mozc"
export BAZELISK_HOME="$BUILD_DIR/bazelisk"
BAZEL_OUTPUT_USER_ROOT="$BUILD_DIR/bazel"

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "macOS 専用です"
command -v git >/dev/null      || die "git が見つかりません"
command -v bazelisk >/dev/null || die "bazelisk が見つかりません（brew install bazelisk）"
command -v python3 >/dev/null  || die "python3 が見つかりません"
xcode-select -p >/dev/null 2>&1 || die "Xcode（またはコマンドラインツール）が必要です"

echo "==> Mozc $MOZC_COMMIT を取得"
mkdir -p "$MOZC_DIR"
if [ ! -d "$MOZC_DIR/.git" ]; then
  git -C "$MOZC_DIR" init -q
  git -C "$MOZC_DIR" remote add origin "$MOZC_REPO"
fi
# 履歴全体は大きいので、必要なコミットだけを取得する
git -C "$MOZC_DIR" fetch --depth 1 origin "$MOZC_COMMIT"
git -C "$MOZC_DIR" checkout -q --force FETCH_HEAD

echo "==> egg-mozc のツールを Mozc のソースツリーに追加"
TOOL_DIR="$MOZC_DIR/src/unix/emacs/egg_mozc"
mkdir -p "$TOOL_DIR"
cp "$ROOT/tools/mozc_user_dict/mozc_user_dict.cc" \
   "$ROOT/tools/mozc_user_dict/BUILD.bazel" "$TOOL_DIR/"

echo "==> ビルド（初回は依存ライブラリのダウンロードを含めて数分〜数十分かかります）"
(
  cd "$MOZC_DIR/src"
  bazelisk --output_user_root="$BAZEL_OUTPUT_USER_ROOT" build --config release_build \
    //server:mozc_server \
    //unix/emacs:mozc_emacs_helper \
    //unix/emacs/egg_mozc:mozc_user_dict
)

echo "==> $BUILD_DIR/bin/ にコピー"
mkdir -p "$BUILD_DIR/bin"
BIN="$MOZC_DIR/src/bazel-bin"
install -m 755 "$BIN/server/mozc_server" \
               "$BIN/unix/emacs/mozc_emacs_helper" \
               "$BIN/unix/emacs/egg_mozc/mozc_user_dict" \
               "$BUILD_DIR/bin/"
# mozc.el も、ビルドした helper と同じバージョンのものを置いておく
install -m 644 "$MOZC_DIR/src/unix/emacs/mozc.el" "$BUILD_DIR/bin/"

ls -l "$BUILD_DIR/bin/"
echo "完了。続けて scripts/install.sh を実行してください。"
