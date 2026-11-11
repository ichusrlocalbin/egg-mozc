;;; its/aynu.el --- Aynu Katakana Input in Egg Input Method Architecture  -*- lexical-binding: nil; -*-

;; Copyright (C) 1999,2000 PFU LIMITED

;; Author: KATAYAMA Yoshio <kate@pfu.co.jp>

;; Keywords: mule, multilingual, input method

;; This file is part of EGG.

;; EGG is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; EGG is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc.,
;; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

;;; Commentary:


;;; Code:

(eval-when-compile
  (require 'its)
  (require 'cl))

(eval-when (compile)
  (defconst its-compaction-enable t))

(defvar its-aynu-enable-zenkaku-alphabet
  (if (boundp 'its-enable-fullwidth-alphabet)
      its-enable-fullwidth-alphabet
    t)
  "*Enable Zenkaku alphabet")

(defvar its-aynu-horizontal      "ー" "*-")	; "-" "―"
(defvar	its-aynu-period          "。 " "*.")	; "." "。"
(defvar	its-aynu-comma           "， " "*,")	; "," "，"
(defvar its-aynu-open-bracket    "「" "*[")	; "［"
(defvar its-aynu-close-bracket   "」" "*]")	; "］"

(defvar its-aynu-enable-double-n nil "*Enable \"nn\" input for \"ン\"")

(defvar its-aynu-kick-conversion-on-space nil "*Start conversion on SPACE")

(eval-when-compile
  (defun its-define-state-aynu (input i-tail output o-tail otherwise)
    "Define following rules:
INPUT + I-TAIL            --> OUTPUT + O-TAIL
INPUT + I-TAIL + '        --> OUTPUT + O-TAIL
INPUT + I-TAIL + vowel    --> (translate INPUT) + I-tail + vowel
INPUT + I-TAIL + OTHERWISE  (see `its-defrule-otherwise')."
    (let ((out (concat output o-tail))
	  state)
      (setq state (its-defrule (concat input i-tail) out))
      (its-defrule (concat input i-tail "'") out)
      (its-defrule-otherwise state nil "[aiueo]" -2)
      (while otherwise
	(its-defrule-otherwise state (concat output (caar otherwise))
			       (nth 1 (car otherwise)) (nth 2 (car otherwise)))
	(setq otherwise (cdr otherwise)))
      (setq state (its-defrule (concat input i-tail "y") (concat out "ィ")))
      (its-make-next-state state -1 out -1)
      (its-defrule-otherwise state out nil -2)
      (its-defrule-otherwise state nil "[u]" -3)
))

  (defconst its-aynu-tail-alist
    (let ((common '(("k" "ㇰ" (("ッ" "[k]"  -1)))
		    ("s" "ㇱ" (("ッ" "[s]"  -1) (nil "[h]" -2)))
		    ("p" "ㇷ゚" (("ッ" "[p]"  -1)))
		    ("m" "ㇺ" (("ン" "[mp]" -1)))
		    ("t" "ッ") ("y" "ィ") ("w" "ゥ"))))
      `((?a ("h" "ㇵ") ("x" "ㇵ") ("r" "ㇻ") ,@common)
	(?i ("h" "ㇶ") ("x" "ㇶ") ("r" "ㇼ") ,@common)
	(?u ("h" "ㇷ") ("x" "ㇷ") ("r" "ㇽ") ,@common)
	(?e ("h" "ㇸ") ("x" "ㇸ") ("r" "ㇾ") ,@common)
	(?o ("h" "ㇹ") ("x" "ㇹ") ("r" "ㇿ") ,@common))))

  (defun its-defrule-aynu (conso vowel output)
    (let ((input (concat conso vowel))
	  (tails (and vowel (cdr (assq (aref vowel 0) its-aynu-tail-alist)))))
      (its-defrule input output)
      (while tails
	(its-define-state-aynu input (caar tails) output (nth 1 (car tails))
			       (nth 2 (car tails)))
	(setq tails (cdr tails)))))

  (defmacro its-define-aynu (&rest rules)
    (let ((defs (list 'progn))
	  conso vowels output)
      (while rules
	(setq vowels '(nil "a" "i" "u" "e" "o")
	      conso  (caar rules)
	      output (cdar rules)
	      rules (cdr rules))
	(while output
	  (when (car output)
	    (setq defs (cons `(its-defrule-aynu ,conso ,(car vowels)
						,(car output))
			     defs)))
	  (setq output (cdr output)
		vowels (cdr vowels))))
      (nreverse defs)))

  (defun its-defrule-aynu-override-yu (conso)
    (let ((output (its-get-output (its-goto-state conso)))
	  state)
      (its-defrule (concat conso "yu")
		   (concat (its-get-output (its-goto-state (concat conso "i")))
			   "ュー"))
      (setq state (its-goto-state (concat conso "y")))
      (its-set-output state (concat output "ィ"))
      (its-make-next-state state -1 output -1)
      (its-defrule-otherwise state output nil -2))))

(define-its-state-machine its-aynu-map
  "roma-aynu-kata" "ア" Aynu
  "Map for Romaji-Aynu-Katakana translation. (Japanese)"

  (defconst its-zenkaku-escape "Z")  ;; Escape character to Zenkaku inputs
  (defconst its-hankaku-escape "~")  ;; Escape character to Hankaku inputs

  (its-defrule-select-mode-temporally "q" downcase)
  (its-defrule-select-mode-temporally "Q" zenkaku-downcase)

  (dolist (small '(("a"  "ァ") ("i"  "ィ") ("u"  "ゥ") ("e"  "ェ") ("o"  "ォ")
		   ("ka" "ヵ")             ("ku" "ㇰ") ("ke" "ヶ")
		               ("si" "ㇱ") ("su" "ㇲ")
		                           ("tu" "ッ")             ("to" "ㇳ")
		                           ("nu" "ㇴ")
		   ("ha" "ㇵ") ("hi" "ㇶ") ("hu" "ㇷ") ("he" "ㇸ") ("ho" "ㇹ")
		                           ("pu" "ㇷ゚")
		                           ("mu" "ㇺ")
		   ("ya" "ャ")             ("yu" "ュ")             ("yo" "ョ")
		   ("ra" "ㇻ") ("ri" "ㇼ") ("ru" "ㇽ") ("re" "ㇾ") ("ro" "ㇿ")
		   ("wa" "ヮ")))
    (its-defrule (concat "x" (car small)) (cadr small)))

  (its-define-aynu
   (""   nil	"ア"   "イ"   "ウ"   "エ"   "オ")
   ("k"  "ㇰ"		"カ"   "キ"   "ク"   "ケ"   "コ")
   ("g"  "グ"   "ガ"   "ギ"   "グ"   "ゲ"   "ゴ")
   ("s"  "ㇲ"		"サ"   "シ"   "ス"   "セ"   "ソ")
   ("z"  nil    "ザ"   "ジ"   "ズ"   "ゼ"   "ゾ")
   ("vs" nil    nil    nil    nil    "セ゚"   nil)
   ("sh" "シャ" "シャ" "シ"   "シュ" "シェ" "ショ")
   ("j"  nil    "ジャ" "ジ"   "ジュ" "ジェ" "ジョ")
   ("t"  "ッ"   "タ"   "チ"   "トゥ" "テ"   "ト")
   ("vt" nil    nil    nil    "ツ゚"   nil    "ト゚")
   ("d"  nil    "ダ"   "ヂ"   "ヅ"   "デ"   "ド")
   ("c"  "ッ"   "チャ" "チ"   "チュ" "チェ" "チョ")
   ("ch" "ッ"   "チャ" "チ"   "チュ" "チェ" "チョ")
   ("n"  "ン"   "ナ"   "ニ"   "ヌ"   "ネ"   "ノ")
   ("h"  "ㇵ"   "ハ"   "ヒ"   "フ"   "ヘ"   "ホ")
   ("b"  nil    "バ"   "ビ"   "ブ"   "ベ"   "ボ")
   ("p"  "ㇷ゚"   "パ"   "ピ"   "プ"   "ペ"   "ポ")
   ("m"  "ㇺ"   "マ"   "ミ"   "ム"   "メ"   "モ")
   ("y"  "ィ"   "ヤ"   "ィ"   "ユ"   "イェ" "ヨ")
   ("r"  "ㇽ"   "ラ"   "リ"   "ル"   "レ"   "ロ")
   ("w"  "ゥ"   "ワ"   "ウィ" "ゥ"   "ウェ" "ウォ"))

  (dolist (yu '("k" "g" "s" "z" "sh" "j" "t" "d"
		"c" "ch" "n" "h" "b" "p" "m" "r"))
    (its-defrule-aynu-override-yu yu))

  (its-defrule "kk" "ッ" -1)
  (its-defrule "ss" "ッ" -1)
  (its-defrule "pp" "ッ" -1)
  (its-defrule "vv" "ッ" -1)

;; SYMBOL Input
  (its-defrule   "z1"   "○")	(its-defrule   "z!"   "●")
  (its-defrule   "z2"   "▽")	(its-defrule   "z@"   "▼")
  (its-defrule   "z3"   "△")	(its-defrule   "z#"   "▲")
  (its-defrule   "z4"   "□")	(its-defrule   "z$"   "■")
  (its-defrule   "z5"   "◇")	(its-defrule   "z%"   "◆")
  (its-defrule   "z6"   "☆")	(its-defrule   "z^"   "★")
  (its-defrule   "z7"   "◎")	(its-defrule   "z&"   "£")
  (its-defrule   "z8"   "¢")	(its-defrule   "z*"   "×")
  (its-defrule   "z9"   "♂")	(its-defrule   "z("   "【")
  (its-defrule   "z0"   "♀")	(its-defrule   "z)"   "】")
  (its-defrule   "z-"   "〜")	(its-defrule   "z_"   "∴")
  (its-defrule   "z="   "≠")	(its-defrule   "z+"   "±")
  (its-defrule   "z\\"  "＼")	(its-defrule   "z|"   "‖")
  (its-defrule   "z`"   "´")	(its-defrule   "z~"   "¨")

  (its-defrule   "zq"   "《")	(its-defrule   "zQ"   "〈")
  (its-defrule   "zw"   "》")	(its-defrule   "zW"   "〉")
					; e
  (its-defrule   "zr"   "々")	(its-defrule   "zR"   "仝")
  (its-defrule   "zt"   "〆")	(its-defrule   "zT"   "§")
					; y u i o
  (its-defrule   "zp"   "〒")	(its-defrule   "zP"   "↑")
  (its-defrule   "z["   "『")	(its-defrule   "z{"   "〔")
  (its-defrule   "z]"   "』")	(its-defrule   "z}"   "〕")
					; a
  (its-defrule   "zs"   "ヽ")	(its-defrule   "zS"   "ヾ")
  (its-defrule   "zd"   "ゝ")	(its-defrule   "zD"   "ゞ")
  (its-defrule   "zf"   "〃")	(its-defrule   "zF"   "→")
  (its-defrule   "zg"   "‐")	(its-defrule   "zG"   "―")
  (its-defrule   "zh"   "←")
  (its-defrule   "zj"   "↓")
  (its-defrule   "zk"   "↑")
  (its-defrule   "zl"   "→")
  (its-defrule   "z;"   "゛")	(its-defrule   "z:"   "゜")
  (its-defrule   "z\'"  "‘")	(its-defrule   "z\""  "“")
					; z
  (its-defrule   "zx"   ":-")	(its-defrule   "zX"   ":-)")
  (its-defrule   "zc"   "〇")	(its-defrule   "zC"   "℃")
  (its-defrule   "zv"   "※")	(its-defrule   "zV"   "÷")
  (its-defrule   "zb"   "°")	(its-defrule   "zB"   "←")
  (its-defrule   "zn"   "′")	(its-defrule   "zN"   "↓")
  (its-defrule   "zm"   "″")	(its-defrule   "zM"   "〓")
  (its-defrule   "z,"   "‥")	(its-defrule   "z<"   "≦")
  (its-defrule   "z."   "…")	(its-defrule   "z>"   "≧")
  (its-defrule   "z/"   "・")	(its-defrule   "z?"   "∞")
  )

(define-its-state-machine-append its-aynu-map
  (if its-aynu-enable-double-n
      (its-defrule "nn" "ン"))

  (its-defrule "-" its-aynu-horizontal)
  (its-defrule "." its-aynu-period)
  (its-defrule "," its-aynu-comma)
  (its-defrule "[" its-aynu-open-bracket)
  (its-defrule "]" its-aynu-close-bracket)

  (unless its-aynu-kick-conversion-on-space
    (its-defrule " " " "))

  (if its-aynu-enable-zenkaku-alphabet
      (progn
	(its-defrule   "1"   "１")  (its-defrule   "2"   "２")
	(its-defrule   "3"   "３")  (its-defrule   "4"   "４")
	(its-defrule   "5"   "５")  (its-defrule   "6"   "６")
	(its-defrule   "7"   "７")  (its-defrule   "8"   "８")
	(its-defrule   "9"   "９")  (its-defrule   "0"   "０")
	(its-defrule   "!"   "！")  (its-defrule   "@"   "＠")
	(its-defrule   "#"   "＃")  (its-defrule   "$"   "＄")
	(its-defrule   "%"   "％")  (its-defrule   "^"   "＾")
	(its-defrule   "&"   "＆")  (its-defrule   "*"   "＊")
	(its-defrule   "("   "（")  (its-defrule   ")"   "）")
	(its-defrule   "="   "＝")  (its-defrule   "`"   "｀")
	(its-defrule   "\\"  "￥")  (its-defrule   "|"   "｜")
	(its-defrule   "_"   "＿")  (its-defrule   "+"   "＋")
	(its-defrule   "{"   "｛")  (its-defrule   "}"   "｝")
	(its-defrule   ":"   "：")  (its-defrule   ";"   "；")
	(its-defrule   "\""  "”")  (its-defrule   "'"   "’")
	(its-defrule   "<"   "＜")  (its-defrule   ">"   "＞")
	(its-defrule   "?"   "？")  (its-defrule   "/"   "／"))
    (progn
      (its-defrule   "1"   "1")  (its-defrule   "2"   "2")
      (its-defrule   "3"   "3")  (its-defrule   "4"   "4")
      (its-defrule   "5"   "5")  (its-defrule   "6"   "6")
      (its-defrule   "7"   "7")  (its-defrule   "8"   "8")
      (its-defrule   "9"   "9")  (its-defrule   "0"   "0")
      (its-defrule   "!"   "!")  (its-defrule   "@"   "@")
      (its-defrule   "#"   "#")  (its-defrule   "$"   "$")
      (its-defrule   "%"   "%")  (its-defrule   "^"   "^")
      (its-defrule   "&"   "&")  (its-defrule   "*"   "*")
      (its-defrule   "("   "(")  (its-defrule   ")"   ")")
      (its-defrule   "="   "=")  (its-defrule   "`"   "`")
      (its-defrule   "\\"  "\\") (its-defrule   "|"   "|")
      (its-defrule   "_"   "_")  (its-defrule   "+"   "+")
      (its-defrule   "{"   "{")  (its-defrule   "}"   "}")
      (its-defrule   ":"   ":")  (its-defrule   ";"   ";")
      (its-defrule   "\""  "\"") (its-defrule   "'"   "'")
      (its-defrule   "<"   "<")  (its-defrule   ">"   ">")
      (its-defrule   "?"   "?")  (its-defrule   "/"   "/"))))

(provide 'its/aynu)

;;; its/aynu.el ends here
