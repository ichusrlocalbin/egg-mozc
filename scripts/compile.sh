#!/bin/bash
# Copyright (c) 2026 ichusrlocalbin
# SPDX-License-Identifier: MIT
#
# 同梱の tamago-tsunagi（Egg）のうち、egg-mozc で使うファイルをバイトコンパイルする。
# コンパイルしなくても動くが、読み込みが速くなる（Emacs 30 以降ではネイティブコンパイルも
# 自動で行われる）。
#
#   EMACS=/Applications/Emacs-31.1.app/Contents/MacOS/Emacs scripts/compile.sh
#
# 環境変数:
#   EMACS  コンパイルに使う Emacs（既定: PATH の emacs）。
#          .elc は、それを読み込む Emacs と同じバージョンでコンパイルすること。
#
# 注意: Egg の .el を変更したり git pull したりしたら、もう一度実行すること。
#       Emacs の既定では、.el の方が新しくても .elc が優先して読み込まれる。
# .elc を消すときは scripts/clean.sh を使う。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EMACS="${EMACS:-emacs}"

die() { echo "error: $*" >&2; exit 1; }

command -v "$EMACS" >/dev/null || die "$EMACS が見つかりません。EMACS=/path/to/Emacs を指定してください"
MAJOR="$("$EMACS" -Q --batch --eval '(princ emacs-major-version)' 2>/dev/null)" || die "$EMACS を実行できません"
if [ "$MAJOR" -lt 30 ]; then
  die "${EMACS} は Emacs ${MAJOR} です。egg-mozc を使う Emacs（30 以降）を指定してください。
  例: EMACS=/Applications/Emacs-31.1.app/Contents/MacOS/Emacs $0"
fi

# egg-mozc で使うファイル（Wnn、Canna、SJ3、Anthy 用の egg/*.el は使わないので除く）。
# 依存の順に並べている（tamago-tsunagi の Makefile.in と同じ）。
FILES=(
  egg-edep.el egg.el egg-com.el egg-cnv.el egg-mlh.el menudiag.el
  its.el its-keydef.el
)
cd "$ROOT/tamago-tsunagi"
for f in its/*.el; do FILES+=("$f"); done

echo "==> Emacs ${MAJOR}（${EMACS}）で ${#FILES[@]} ファイルをコンパイル"
failed=()
for f in "${FILES[@]}"; do
  # docomp.el は tamago-tsunagi 付属のコンパイル用設定（load-path などを設定する）
  if "$EMACS" -Q --batch -l ./docomp.el -f batch-byte-compile "$f" >/dev/null 2>&1; then
    echo "  ok      $f"
  else
    echo "  FAILED  $f"
    failed+=("$f")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "コンパイルできなかったファイルがあります: ${failed[*]}" >&2
  echo "詳しく見るには: (cd tamago-tsunagi && $EMACS -Q --batch -l ./docomp.el -f batch-byte-compile ${failed[0]})" >&2
  exit 1
fi
echo "完了"
