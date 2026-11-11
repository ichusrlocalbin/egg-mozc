;;; egg-mozc.el --- Use Mozc from the Egg (Tamago) input method  -*- lexical-binding: t; -*-

;; Copyright (c) 2026 ichusrlocalbin
;; SPDX-License-Identifier: MIT

;; Keywords: i18n, input method, Japanese
;; URL: https://github.com/ichusrlocalbin/egg-mozc
;; Package-Requires: ((emacs "30.1") (mozc "0"))

;;; Commentary:

;; Egg（たまご、tamago-tsunagi）の画面とキー操作のまま、
;; かな漢字変換に Mozc を使うための入口のファイル。
;;
;;   (add-to-list 'load-path "/path/to/egg-mozc/lisp")
;;   (require 'egg-mozc)
;;   (setq default-input-method "japanese-egg-mozc")
;;
;; このファイルがすること：
;; - 同梱の tamago-tsunagi を load-path に加える
;; - 入力メソッド "japanese-egg-mozc" を登録する
;; - mozc_emacs_helper などの場所を設定する
;; - Emacs 31 で Egg を動かすための互換処理を入れる
;;
;; 変換の処理（Egg のバックエンド）は egg/mozc.el にある。

;;; Code:

(defgroup egg-mozc nil
  "Use Mozc from the Egg input method."
  :group 'leim
  :prefix "egg-mozc-")

(defconst egg-mozc-lisp-directory
  (file-name-directory (or load-file-name buffer-file-name))
  "egg-mozc の Lisp ファイルがあるディレクトリ。")

(defcustom egg-mozc-tamago-directory
  (expand-file-name "../tamago-tsunagi/" egg-mozc-lisp-directory)
  "同梱の tamago-tsunagi（Egg）のディレクトリ。"
  :type 'directory
  :group 'egg-mozc)

(defcustom egg-mozc-libexec-directory
  (expand-file-name "~/.local/libexec/egg-mozc/")
  "mozc_emacs_helper と mozc_user_dict をインストールしたディレクトリ。
scripts/install.sh の PREFIX を変えた場合は、PREFIX/libexec/egg-mozc/ にする。"
  :type 'directory
  :group 'egg-mozc)

(add-to-list 'load-path egg-mozc-tamago-directory)
(add-to-list 'load-path egg-mozc-lisp-directory)

;;; mozc.el（Google）の設定

(require 'mozc)

(defun egg-mozc--program (name)
  (expand-file-name name egg-mozc-libexec-directory))

;; ユーザーが変えていなければ、インストール先の helper を使う
(when (equal mozc-helper-program-name "mozc_emacs_helper")
  (setq mozc-helper-program-name (egg-mozc--program "mozc_emacs_helper")))

;;; Emacs 31 で Egg を動かすための互換処理

;; `buffer-has-markers-at' は Emacs から削除された。egg-cnv.el の
;; `egg-insert-new-bunsetsu' が使っている。Lisp からはマーカーの有無を
;; 調べられないので、常に nil を返す（Egg は一般の場合の処理をする）。
(unless (fboundp 'buffer-has-markers-at)
  (defun buffer-has-markers-at (_position) nil))

;; Egg は文節を `intangible' テキストプロパティで表し（カーソルが文節の
;; 途中に止まらない）、`point-entered' / `point-left' でフェンスへの出入りを
;; 検出する。Emacs 25 以降は `inhibit-point-motion-hooks' の既定値が t で
;; これらが効かないため、Egg を使うバッファでだけ nil にする。
(defun egg-mozc--enable-point-motion-hooks ()
  (with-no-warnings
    (setq-local inhibit-point-motion-hooks nil)))
(add-hook 'egg-mode-hook #'egg-mozc--enable-point-motion-hooks)

;;; 入力メソッドの登録

(autoload 'egg-activate-mozc "egg/mozc"
  "Activate the Mozc backend of Egg." t)

(register-input-method
 "japanese-egg-mozc" "Japanese" #'egg-activate-mozc
 "あ.." "Romaji -> Hiragana -> Kanji&Kana (Egg + Mozc)"
 'its-select-hiragana)

(provide 'egg-mozc)
;;; egg-mozc.el ends here
