# egg-mozc

Emacs（macOS）で、**Egg（たまご）の画面とキー操作のまま、かな漢字変換に Mozc を使う**ための
パッケージです。

Egg-Anthy に慣れた人が、操作を変えずに変換エンジンだけを Mozc にすることを目指しています。

```text
|きょうはいいてんき!|      ← ローマ字で入力（Egg のフェンス）
|今日は いい天気|          ← SPC で変換。C-f/C-b で文節移動、C-i/C-o で伸縮、C-n/C-p で候補
今日はいい天気             ← C-m で確定
```

- 変換エンジン：Google の [Mozc](https://github.com/google/mozc)（OSS 版）をソースからビルドして使う
- 画面・キー操作：[tamago-tsunagi](https://osdn.net/projects/tamago-tsunagi/)（Egg）5.0.7.1 を同梱し、
  Emacs 31 で動くように修正したもの
- macOS の IME（Google 日本語入力や Mozc.app）はインストールしない。Emacs の中だけで完結する

## 動作環境

- macOS（Apple Silicon で確認）
- GNU Emacs 30 以降（Emacs 31.1 で確認）
- ビルドに必要なもの
  - Xcode（またはコマンドラインツール）
  - [Bazelisk](https://github.com/bazelbuild/bazelisk)（`brew install bazelisk`）
  - git、python3

egg-mozc は、Mozc と通信するために Google の `mozc.el` を使います。`mozc.el` は
`scripts/build.sh` が Mozc のソースから取り出してインストールするので、別に用意する必要はありません
（MELPA の `mozc` パッケージを使うこともできます。後述）。

## インストール

### 1. 取得とビルド

```bash
git clone https://github.com/ichusrlocalbin/egg-mozc.git
cd egg-mozc
scripts/build.sh
```

`scripts/build.sh` が行うこと：

1. `scripts/mozc-commit` に書かれたコミットの Mozc を `build/mozc/` に取得する（必要なコミットだけを取得）
2. 単語登録用のツール `tools/mozc_user_dict/` を、Mozc のソースツリーに `src/unix/emacs/egg_mozc/` として追加する
   （Mozc 本体のファイルは変更しない）
3. Bazel で `mozc_server`、`mozc_emacs_helper`、`mozc_user_dict` をビルドし、`build/bin/` に置く

初回は、Bazel 本体と依存ライブラリのダウンロードを含めて数分〜数十分かかります。

ダウンロードしたものとキャッシュは、すべて `build/` の下に作ります（`~/Library/Caches` は使いません）。
合わせて 1GB ほどになります。

| 場所 | 中身 |
|---|---|
| `build/mozc/` | Mozc のソース |
| `build/bazelisk/` | Bazel 本体（Bazelisk がダウンロードしたもの） |
| `build/bazel/` | 依存ライブラリのダウンロードと、ビルド途中の生成物 |
| `build/bin/` | できた実行ファイルと `mozc.el` |

インストールしたあとは、`scripts/clean.sh` で `build/` をまとめて削除できます
（インストールしたものは消えません）。`build/bazel/` には書き込み禁止のファイルがあるため、
`rm -rf build` ではなく `scripts/clean.sh` を使ってください。

### 2. インストール

```bash
scripts/install.sh
```

- 実行ファイルを `~/.local/libexec/egg-mozc/` に入れる
- `mozc_server` を、ユーザー単位の LaunchAgent（`~/Library/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist`）
  として登録する

インストール先は `PREFIX` で変えられます。実行ファイルは `$PREFIX/libexec/egg-mozc/` に入ります。
たとえば `~/usr` に入れる場合：

```bash
PREFIX=~/usr scripts/install.sh      # → ~/usr/libexec/egg-mozc/
```

アンインストールするときも、同じ `PREFIX` を指定します（`PREFIX=~/usr scripts/uninstall.sh`）。

macOS 版の Mozc は、変換サーバー（`mozc_server`）を launchd 経由で起動し、launchd に登録された
Mach サービスで通信します。そのため IME 本体を入れない場合でも、この登録が必要です。
サーバーが常に動き続けることはなく、Emacs から要求があったときだけ起動します。

### 3. Emacs の設定

初期化ファイル（`~/.emacs.d/init.el` など）に次を追加します。`/path/to/egg-mozc` は clone した場所です。

```elisp
;; Google の mozc.el（scripts/install.sh がインストールしたもの）
(add-to-list 'load-path "~/.local/libexec/egg-mozc")
;; egg-mozc
(add-to-list 'load-path "/path/to/egg-mozc/lisp")
(require 'egg-mozc)
(setq default-input-method "japanese-egg-mozc")
```

`PREFIX` を変えてインストールした場合は、`~/.local` の部分を変え、`(require 'egg-mozc)` の前に
`egg-mozc-libexec-directory` も設定します。`PREFIX=~/usr` の場合：

```elisp
(add-to-list 'load-path "~/usr/libexec/egg-mozc")
(add-to-list 'load-path "/path/to/egg-mozc/lisp")
(setq egg-mozc-libexec-directory "~/usr/libexec/egg-mozc/")
(require 'egg-mozc)
(setq default-input-method "japanese-egg-mozc")
```

#### MELPA の mozc パッケージを使う場合（optional）

すでに MELPA で `mozc` パッケージ（Google の `mozc.el`）を入れている場合は、そちらを使うこともできます。
ただし、`mozc.el` と、ビルドした `mozc_emacs_helper` のバージョンが離れていると、うまく通信できない
ことがあります。迷ったら上の方法（ビルドで作られる `mozc.el`）を使ってください。

1. MELPA を使えるようにしていなければ、初期化ファイルに追加します。

   ```elisp
   (require 'package)
   (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
   (package-initialize)
   ```

2. `M-x package-refresh-contents`、続けて `M-x package-install RET mozc RET` を実行します。

3. 初期化ファイルの設定から、`~/.local/libexec/egg-mozc` を load-path に加える行を除きます
   （両方あると、どちらの `mozc.el` が読み込まれるかが load-path の順序で決まり、紛らわしくなります）。

   ```elisp
   (add-to-list 'load-path "/path/to/egg-mozc/lisp")
   (require 'egg-mozc)          ; package-initialize より後に書く
   (setq default-input-method "japanese-egg-mozc")
   ```

どちらの方法でも、helper（`mozc_emacs_helper`）は `scripts/install.sh` がインストールしたものが使われます。

## 使い方

`C-\` で入力をオン・オフします。キー操作は Egg と同じです。

| キー | 入力中（ローマ字 → かな） | 変換中 |
|---|---|---|
| SPC | 変換 | 次の候補 |
| C-m / RET | ひらがなのまま確定 | すべて確定 |
| C-f / C-b | 1文字移動 | 文節を移動 |
| C-i / C-o | — | 文節を縮める / 伸ばす |
| C-n / C-p | — | 次 / 前の候補 |
| C-k | カーソルから後ろを削除 | カーソルより前の文節だけ確定 |
| M-h / M-k | ひらがな / カタカナ | ひらがな / カタカナ |
| M-s | — | 候補一覧から選ぶ |
| C-c / C-g | 入力を取り消す | 変換を取り消す（入力中に戻る） |

### 単語登録

`M-x egg-toroku-region`（リージョンの単語を登録）または、変換中に `C-t` を使います。
読みを入力し、メニューで品詞を選ぶと、Mozc のユーザー辞書（「Emacs」という名前の辞書）に登録されます。
登録した単語はすぐに変換に使われます。

- `M-x egg-mozc-list-words`：登録した単語の一覧
- `M-x egg-mozc-delete-word`：登録の削除

## しくみ

```text
Emacs
 ├─ Egg（tamago-tsunagi）     画面（フェンス）とキー操作
 │    └─ egg/mozc.el          Egg のバックエンド。Egg の要求を Mozc のキー操作に置き換える
 └─ mozc.el                   mozc_emacs_helper との通信
        │ 標準入出力（S式）
        ▼
   mozc_emacs_helper ──(Mach IPC / launchd)──▶ mozc_server
```

`mozc_emacs_helper` はキー入力しか受け付けないため、`egg/mozc.el` は Egg の要求を次のように置き換えます。

| Egg の要求 | Mozc への操作 |
|---|---|
| 変換開始 | 読みを key_string としてまとめて送り、Space |
| 候補一覧 | Home と Right で文節を選び、出力の候補一覧を読む |
| 候補の選択 | Down / Up |
| 文節の伸縮 | Shift+Left / Shift+Right |
| 確定 / 取り消し | Enter（Mozc が学習する） / Escape |

## Emacs 31 で Egg を動かすための修正

同梱の tamago-tsunagi は、`tamago-tsunagi/` に手を加えていない 5.0.7.1 を最初のコミットとして入れ、
そのあとの修正を1件ずつコミットしています（`git log -- tamago-tsunagi` で確認できます）。

| ファイル | 問題 | 修正 |
|---|---|---|
| `its.el` | Emacs 30 からシンボル表（obarray）が専用の型になった | `make-vector` を `obarray-make` に変更 |
| `egg-com.el` | 削除された `make-coding-system` を呼んでいる | 呼び出しを条件付きにした（Wnn などのネットワーク用で、Mozc では使わない） |
| `egg.el`、`menudiag.el` | 削除された `inactivate-input-method` などを使っている | `deactivate-input-method` に変更 |
| すべての `.el` | `lexical-binding` の指定がなく、読み込むたびに警告が出る | 1行目に `lexical-binding: nil` を追加（Egg は動的スコープ前提のため） |
| `its.el` | `?[` `?]` の文字リテラルで警告が出る | `?\[` `?\]` に変更 |

Egg のファイルを変えずに `lisp/egg-mozc.el` で対応しているもの：

- 削除された `buffer-has-markers-at` の代わりの関数を定義
- Egg は `intangible` テキストプロパティで文節を表すが、Emacs 25 以降は既定で効かない。
  Egg を使うバッファでだけ `inhibit-point-motion-hooks` を nil にする

## 社内プロキシ（TLS を中継するプロキシ）の環境でビルドする

Bazel は Java で動き、Java は自分の証明書ストアしか信頼しません。プロキシの CA 証明書を信頼させないと、
`PKIX path building failed` で依存の取得に失敗します。

```bash
# JDK の標準の証明書に、プロキシの CA 証明書を加えたストアを作る
JH=$(/usr/libexec/java_home)        # または使っている JDK のホーム
keytool -importkeystore -noprompt \
  -srckeystore "$JH/lib/security/cacerts" -srcstorepass changeit \
  -destkeystore ~/.bazel-truststore.p12 -deststoretype PKCS12 -deststorepass changeit
keytool -importcert -noprompt -alias proxy-ca -file /path/to/proxy-ca.pem \
  -keystore ~/.bazel-truststore.p12 -storepass changeit
```

`~/.bazelrc` に次を追加します。

```text
startup --host_jvm_args=-Djavax.net.ssl.trustStore=/Users/YOU/.bazel-truststore.p12
startup --host_jvm_args=-Djavax.net.ssl.trustStorePassword=changeit
startup --host_jvm_args=-Djavax.net.ssl.trustStoreType=PKCS12
```

## アンインストール

```bash
scripts/uninstall.sh
```

LaunchAgent と実行ファイルを削除します。Mozc の学習データとユーザー辞書
（`~/Library/Application Support/Mozc/`）は残します。

## 注意と制限

- Mozc の IME（`/Library/Input Methods/Mozc.app`）とは、同じ名前の LaunchAgent を使うので同時に使えません
- Mozc の設定画面と辞書ツール（Qt が必要な GUI）はビルドしていません。単語登録は `egg-toroku-region` で行えます
- 確認したのは macOS のみです

## ライセンス

このリポジトリには、ライセンスの異なるものが含まれています。

| 対象 | ライセンス |
|---|---|
| `tamago-tsunagi/`（Egg 本体と、Emacs 31 用の修正） | GPL-2.0-or-later（`tamago-tsunagi/COPYING`） |
| `lisp/`、`tools/`、`scripts/`、ドキュメント（egg-mozc のために書いたもの） | MIT（`LICENSE`） |
| `macos/org.mozc.inputmethod.Japanese.Converter.plist.in` | BSD-3-Clause（Mozc の plist をもとにしたもの。下記参照） |

ビルド時に取得するもの（このリポジトリには含まない）：

| 対象 | ライセンス |
|---|---|
| Mozc（mozc_server、mozc_emacs_helper、mozc.el を含む） | BSD-3-Clause（Mozc の `LICENSE`） |

Egg と組み合わせて配布・利用する場合、全体としては GPL の条件に従います。

`macos/org.mozc.inputmethod.Japanese.Converter.plist.in` は、Mozc の
`src/mac/installer/LaunchAgents/org.mozc.inputmethod.Japanese.Converter.plist` をもとに、
起動するプログラムのパスだけを変えたものです。

## 謝辞

- Egg（たまご）、tamago-tsunagi の開発者のみなさん
- Mozc の開発者のみなさん
