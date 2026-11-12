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
;;   (add-to-list 'load-path "~/.local/share/emacs/site-lisp/egg-mozc")
;;   (require 'egg-mozc)
;;   (setq default-input-method "japanese-egg-mozc")
;;
;; scripts/install.sh は、Lisp 一式を PREFIX/share/emacs/site-lisp/egg-mozc/ に、
;; 実行ファイルを PREFIX/libexec/egg-mozc/ に入れる（PREFIX の既定は ~/.local）。
;;
;;   PREFIX/share/emacs/site-lisp/egg-mozc/
;;     egg-mozc.el、egg/mozc.el   このパッケージ
;;     tamago-tsunagi/            Egg 本体
;;     mozc/mozc.el               Google の mozc.el（Mozc のビルドでできたもの）
;;   PREFIX/libexec/egg-mozc/
;;     mozc_server、mozc_emacs_helper、mozc_user_dict
;;
;; リポジトリの lisp/ を直接 load-path に加えても動く（開発用）。その場合は
;; tamago-tsunagi は ../tamago-tsunagi/ を使う。
;;
;; このファイルがすること：
;; - tamago-tsunagi と mozc.el を load-path に加える
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

(defun egg-mozc--first-directory (&rest dirs)
  "DIRS のうち、最初に存在するディレクトリを返す。なければ最初のものを返す。"
  (let ((found (car dirs)))
    (catch 'found
      (dolist (dir dirs)
        (when (file-directory-p dir) (setq found dir) (throw 'found nil))))
    found))

(defcustom egg-mozc-tamago-directory
  (egg-mozc--first-directory
   (expand-file-name "tamago-tsunagi/" egg-mozc-lisp-directory)      ; インストール先
   (expand-file-name "../tamago-tsunagi/" egg-mozc-lisp-directory))  ; リポジトリ
  "同梱の tamago-tsunagi（Egg）のディレクトリ。"
  :type 'directory
  :group 'egg-mozc)

(defcustom egg-mozc-libexec-directory
  (egg-mozc--first-directory
   ;; PREFIX/share/emacs/site-lisp/egg-mozc/ から見た PREFIX/libexec/egg-mozc/
   (expand-file-name "../../../../libexec/egg-mozc/" egg-mozc-lisp-directory)
   (expand-file-name "~/.local/libexec/egg-mozc/"))
  "mozc_emacs_helper と mozc_user_dict をインストールしたディレクトリ。
既定では、egg-mozc.el のインストール先と同じ PREFIX の libexec/egg-mozc/ を使う。"
  :type 'directory
  :group 'egg-mozc)

(defcustom egg-mozc-mozc-el-directory
  (let ((dir (expand-file-name "mozc/" egg-mozc-lisp-directory)))
    (and (file-exists-p (expand-file-name "mozc.el" dir)) dir))
  "Google の mozc.el があるディレクトリ。load-path の先頭に加える。
既定は、scripts/install.sh が入れたもの（helper と同じ Mozc のビルドでできたもの）。
MELPA の mozc パッケージなど、load-path にある別の mozc.el を使うときは nil にする。"
  :type '(choice (const :tag "load-path の mozc.el を使う" nil) directory)
  :group 'egg-mozc)

(add-to-list 'load-path egg-mozc-tamago-directory)
(add-to-list 'load-path egg-mozc-lisp-directory)
(when egg-mozc-mozc-el-directory
  (add-to-list 'load-path egg-mozc-mozc-el-directory))

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

;;; 数字の入力

(defcustom egg-mozc-halfwidth-digits t
  "non-nil なら、ひらがな・カタカナの入力中に数字を半角（123）で入れる。
全角の数字は、入力中に Z に続けて数字（Z1 → １）を打つか、変換中に M-> で入れる。
nil なら Egg の既定のまま（`its-hira-enable-zenkaku-alphabet' が t なら全角）。
記号（！、？ など）は変えない。ひらがなの入力を始める前に設定すること。"
  :type 'boolean
  :group 'egg-mozc)

(declare-function its-defrule "its")
(defvar its-current-map)

(defun egg-mozc--add-halfwidth-digit-rules (map)
  "ITS の変換表 MAP（シンボル）で、数字を半角にする規則を加える。
MAP がまだ読み込まれていなければ、読み込まれたときに加える。
（its.el の `define-its-state-machine-append' と同じことを関数で行う）"
  (let ((func (lambda ()
                (when egg-mozc-halfwidth-digits
                  (let ((its-current-map map))
                    (dotimes (i 10)
                      (let ((digit (number-to-string i)))
                        (its-defrule digit digit nil t))))))))
    (if (boundp map)
        (funcall func)
      (add-hook (intern (concat (symbol-name map) "-hook")) func t))))

(with-eval-after-load 'its
  (egg-mozc--add-halfwidth-digit-rules 'its-hira-map)
  (egg-mozc--add-halfwidth-digit-rules 'its-kata-map))

;;; 入力メソッドの登録

(autoload 'egg-activate-mozc "egg/mozc"
  "Activate the Mozc backend of Egg." t)

(register-input-method
 "japanese-egg-mozc" "Japanese" #'egg-activate-mozc
 "あ.." "Romaji -> Hiragana -> Kanji&Kana (Egg + Mozc)"
 'its-select-hiragana)

(provide 'egg-mozc)
;;; egg-mozc.el ends here
