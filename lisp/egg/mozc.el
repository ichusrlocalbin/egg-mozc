;;; egg/mozc.el --- Mozc conversion backend for Egg  -*- lexical-binding: t; -*-

;; Copyright (c) 2026 ichusrlocalbin
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; Egg（tamago-tsunagi）のかな漢字変換バックエンドとして Mozc を使う。
;; 画面表示（|かんじ| のフェンス）とキー操作は Egg がそのまま担当し、
;; このファイルは Egg からの「変換」「候補」「文節の伸縮」「確定」の要求を
;; Mozc に伝える。
;;
;; Mozc とは mozc.el（Google）の helper プロセス（mozc_emacs_helper）で通信する。
;; helper はキー入力しか受け付けないので、各要求をキー入力に置き換える。
;;
;;   変換開始   読み（ひらがな）を key_string だけでまとめて送り、Space
;;   文節を選ぶ Home のあと Right を n 回
;;   候補一覧   出力の all-candidate-words（`egg-mozc-hidden-candidate-regexp' に
;;              合うものは隠す。M-< / M-> で呼び出せる）
;;   候補を選ぶ Down / Up を差の回数だけ
;;   文節の伸縮 Shift+Left / Shift+Right を差の回数だけ
;;   確定       Enter（Mozc が学習する）。中止や一部だけの確定は Escape
;;
;; 変換1回ごとに Mozc のセッションを1つ作り、変換が終わったら削除する。
;;
;; 単語登録には mozc_user_dict（tools/mozc_user_dict）を使う。

;;; Code:

(require 'cl-lib)
(require 'egg)
(require 'menudiag)
(require 'mozc)

(defgroup egg-mozc-backend nil
  "Mozc backend for Egg."
  :group 'egg-mozc
  :prefix "egg-mozc-")

(defcustom egg-mozc-debug nil
  "non-nil なら、Mozc に送ったキーと文節を *Messages* に出す。"
  :type 'boolean
  :group 'egg-mozc-backend)

(defcustom egg-mozc-hidden-candidate-regexp "[０-９\uff61-\uff9f]"
  "この正規表現に合う候補は、候補一覧（Space、C-n、M-s など）に出さない。
既定では全角数字（１２３）と半角カタカナ（ｶﾅ）を含む候補を隠す。
隠した候補も、変換中に M-<（半角）や M->（全角）で選べる。
nil なら、Mozc の候補をすべて出す。"
  :type '(choice (const :tag "すべて出す" nil) regexp)
  :group 'egg-mozc-backend)

;;; Egg への登録

(defconst egg-mozc--backend-functions
  '((egg-start-conversion       . egg-mozc-start-conversion)
    (egg-get-bunsetsu-source    . egg-mozc-bunsetsu-source)
    (egg-get-bunsetsu-converted . egg-mozc-bunsetsu-converted)
    (egg-list-candidates        . egg-mozc-list-candidates)
    (egg-decide-candidate       . egg-mozc-decide-candidate)
    (egg-change-bunsetsu-length . egg-mozc-change-bunsetsu-length)
    (egg-end-conversion         . egg-mozc-end-conversion)
    (egg-special-candidate      . egg-mozc-special-candidate)
    (egg-word-registration      . egg-mozc-word-registration)
    (egg-get-source-language    . egg-mozc-language)
    (egg-get-converted-language . egg-mozc-language))
  "Egg の汎用関数と、それを実装するこのファイルの関数の対応。")

;; Egg はバックエンドのシンボルの属性リストから実装を探す
(setplist 'egg-mozc-backend nil)
(dolist (pair egg-mozc--backend-functions)
  (put 'egg-mozc-backend (car pair) (cdr pair)))

(defconst egg-mozc--backend-alist '((Japanese ((egg-mozc-backend))))
  "`egg-mode' に渡す、言語とバックエンドの対応。")

;;; Mozc のセッション

(cl-defstruct (egg-mozc--session (:constructor egg-mozc--session-make))
  id                ; mozc_emacs_helper のセッション ID
  process           ; helper プロセス
  output            ; 最後に受け取った出力（mozc::commands::Output）
  (open t))         ; まだ使えるか

(defvar egg-mozc--sessions nil
  "変換中のセッションの一覧。")

(defun egg-mozc--open-session ()
  "新しい Mozc セッションを作って返す。"
  (let ((mozc-session-id nil)
        (mozc-session-process nil))
    (mozc-session-create)
    (let ((s (egg-mozc--session-make :id mozc-session-id
                                     :process mozc-session-process)))
      (push s egg-mozc--sessions)
      s)))

(defun egg-mozc--send (session &rest key)
  "SESSION にキー KEY を送り、出力を返す。"
  (unless (egg-mozc--session-open session)
    (egg-error "egg-mozc: the Mozc session is already closed"))
  (let* ((mozc-session-id (egg-mozc--session-id session))
         (mozc-session-process (egg-mozc--session-process session))
         (output (apply #'mozc-session-execute-command 'SendKey key)))
    (unless output
      (egg-error "egg-mozc: no response from mozc_emacs_helper"))
    (when egg-mozc-debug
      (message "egg-mozc: %S => %S" key (egg-mozc--segment-values output)))
    (setf (egg-mozc--session-output session) output)))

(defun egg-mozc--close-session (session)
  "SESSION を削除する。"
  (when (egg-mozc--session-open session)
    (let ((mozc-session-id (egg-mozc--session-id session))
          (mozc-session-process (egg-mozc--session-process session)))
      (ignore-errors (mozc-session-execute-command 'DeleteSession)))
    (setf (egg-mozc--session-open session) nil))
  (setq egg-mozc--sessions (delq session egg-mozc--sessions)))

(defun egg-mozc--finalize ()
  "Egg の終了時に、残っているセッションをすべて削除する。"
  (mapc #'egg-mozc--close-session (copy-sequence egg-mozc--sessions)))

(egg-set-finalize-backend '(egg-mozc--finalize))

;;; Mozc の出力の読み取り

(defun egg-mozc--segments (output)
  "OUTPUT の preedit の文節を返す（各要素は alist）。"
  (mozc-protobuf-get output 'preedit 'segment))

(defun egg-mozc--segment-values (output)
  (mapcar (lambda (seg) (alist-get 'value seg)) (egg-mozc--segments output)))

(defun egg-mozc--candidates (output)
  "OUTPUT の候補を（注目中の番号 . 候補の文字列のリスト）で返す。なければ nil。"
  (let* ((words (mozc-protobuf-get output 'all-candidate-words))
         (cands (alist-get 'candidates words)))
    (and cands
         (cons (or (alist-get 'focused-index words) 0)
               (mapcar (lambda (c) (alist-get 'value c)) cands)))))

;;; 文節（Egg の bunsetsu の中身）

(cl-defstruct (egg-mozc--clause (:constructor egg-mozc--clause-make))
  session           ; この文節が属する Mozc セッション
  index             ; セッションの中での文節の番号（0 から）
  reading           ; 読み
  surface           ; 変換直後の文字列
  all               ; Mozc の候補の文字列のリスト（取得するまでは nil）
  candidates        ; そのうち Egg に見せる候補のリスト
  indices           ; candidates のそれぞれが all の何番目か
  (selected 0))     ; candidates の中で選ばれている番号

(defun egg-mozc--clause (bunsetsu)
  (egg-bunsetsu-get-info bunsetsu))

(defun egg-mozc--bunsetsu-list (session output from)
  "OUTPUT の FROM 番目以降の文節を、Egg の bunsetsu のリストにして返す。"
  (cl-loop for seg in (nthcdr from (egg-mozc--segments output))
           for i from from
           collect (egg-bunsetsu-create
                    'egg-mozc-backend
                    (egg-mozc--clause-make :session session :index i
                                           :reading (alist-get 'key seg)
                                           :surface (alist-get 'value seg)))))

(defun egg-mozc--focus (clause)
  "Mozc 側で CLAUSE の文節を選び、出力を返す。"
  (let* ((session (egg-mozc--clause-session clause))
         (output (egg-mozc--send session 'home)))
    (dotimes (_ (egg-mozc--clause-index clause) output)
      (setq output (egg-mozc--send session 'right)))))

(defun egg-mozc--fetch-candidates (clause)
  "CLAUSE の候補を Mozc から取得して覚える。"
  (let* ((session (egg-mozc--clause-session clause))
         (found (egg-mozc--candidates (egg-mozc--focus clause))))
    ;; 候補一覧がまだ出ていなければ、一度次の候補へ進めて戻す
    (unless found
      (egg-mozc--send session 'down)
      (setq found (egg-mozc--candidates (egg-mozc--send session 'up))))
    (unless found
      (setq found (list 0 (egg-mozc--clause-surface clause))))
    (let ((focused (car found)) words indices)
      ;; 隠す候補を除く。ただし Mozc が今選んでいる候補（変換結果）は残す
      (cl-loop for word in (cdr found)
               for i from 0
               when (or (= i focused) (not (egg-mozc--hidden-p word)))
               do (push word words) (push i indices))
      (setf (egg-mozc--clause-all clause) (cdr found)
            (egg-mozc--clause-candidates clause) (nreverse words)
            (egg-mozc--clause-indices clause) (nreverse indices)
            (egg-mozc--clause-selected clause)
            (or (cl-position focused (egg-mozc--clause-indices clause)) 0)))))

(defun egg-mozc--hidden-p (word)
  (and egg-mozc-hidden-candidate-regexp
       (string-match-p egg-mozc-hidden-candidate-regexp word)))

(defun egg-mozc--reveal (clause i)
  "Mozc の I 番目の候補を CLAUSE の候補に加え（隠していた場合）、その番号を返す。"
  (let ((indices (egg-mozc--clause-indices clause)))
    (or (cl-position i indices)
        (let ((pos (cl-count-if (lambda (j) (< j i)) indices))
              (word (nth i (egg-mozc--clause-all clause))))
          (when (<= pos (egg-mozc--clause-selected clause))
            (cl-incf (egg-mozc--clause-selected clause)))
          (setf (egg-mozc--clause-candidates clause)
                (append (cl-subseq (egg-mozc--clause-candidates clause) 0 pos)
                        (list word)
                        (nthcdr pos (egg-mozc--clause-candidates clause)))
                (egg-mozc--clause-indices clause)
                (append (cl-subseq indices 0 pos) (list i) (nthcdr pos indices)))
          pos))))

;;; Egg から呼ばれる関数

(defun egg-mozc-language (_bunsetsu) 'Japanese)

(defun egg-mozc-bunsetsu-source (bunsetsu)
  (egg-mozc--clause-reading (egg-mozc--clause bunsetsu)))

(defun egg-mozc-bunsetsu-converted (bunsetsu)
  (let ((clause (egg-mozc--clause bunsetsu)))
    (if (egg-mozc--clause-candidates clause)
        (nth (egg-mozc--clause-selected clause)
             (egg-mozc--clause-candidates clause))
      (egg-mozc--clause-surface clause))))

(defun egg-mozc-start-conversion (_backend reading &optional _context)
  "READING を変換して、bunsetsu のリストを返す。"
  ;; Mozc の読みはひらがななので、カタカナで入力された読みもひらがなにする
  (let ((reading (japanese-hiragana (substring-no-properties reading)))
        (session (egg-mozc--open-session)))
    ;; 読みは key_string だけで渡す。キーコードを添えると、そのキーの英字
    ;; （a、A、ａ、Ａ など）が候補に混ざる
    (egg-mozc--send session reading)
    (or (egg-mozc--bunsetsu-list session (egg-mozc--send session 'space) 0)
        (list (egg-bunsetsu-create
               'egg-mozc-backend
               (egg-mozc--clause-make :session session :index 0
                                      :reading reading :surface reading))))))

(defun egg-mozc-list-candidates (bunsetsu-list _prev-b _next-b _major)
  "先頭の bunsetsu の候補を（選ばれている番号 . 候補のリスト）で返す。"
  (let ((clause (egg-mozc--clause (car bunsetsu-list))))
    (unless (egg-mozc--clause-candidates clause)
      (egg-mozc--fetch-candidates clause))
    (cons (egg-mozc--clause-selected clause)
          (egg-mozc--clause-candidates clause))))

(defun egg-mozc-decide-candidate (bunsetsu-list pos _prev-b _next-b)
  "先頭の bunsetsu で POS 番目の候補を選ぶ。Mozc 側の選択も合わせる。"
  (let* ((bunsetsu (car bunsetsu-list))
         (clause (egg-mozc--clause bunsetsu))
         (session (egg-mozc--clause-session clause)))
    (unless (egg-mozc--clause-candidates clause)
      (egg-mozc--fetch-candidates clause))
    (let* ((target (nth pos (egg-mozc--clause-indices clause)))
           (current (or (car (egg-mozc--candidates (egg-mozc--focus clause)))
                        target))
           (steps (- target current)))
      (dotimes (_ (abs steps))
        (egg-mozc--send session (if (> steps 0) 'down 'up))))
    (setf (egg-mozc--clause-selected clause) pos)
    (list (list bunsetsu))))

(defun egg-mozc-change-bunsetsu-length (bunsetsu-list _prev-b _next-b length _major)
  "先頭の bunsetsu の読みの長さを LENGTH 文字にする。
戻り値は Egg の形式：(list (list 新しい文節) nil (後続の文節…))。"
  (let* ((clause (egg-mozc--clause (car bunsetsu-list)))
         (session (egg-mozc--clause-session clause))
         (index (egg-mozc--clause-index clause))
         (delta (- length (length (egg-mozc--clause-reading clause))))
         (output (egg-mozc--focus clause)))
    (dotimes (_ (abs delta))
      (setq output (egg-mozc--send session (if (> delta 0) 'right 'left) 'shift)))
    (let ((new (egg-mozc--bunsetsu-list session output index)))
      (and new (list (list (car new)) nil (cdr new))))))

(defun egg-mozc-end-conversion (bunsetsu-list abort)
  "変換を終える。全文節を確定するときだけ Mozc でも確定して学習させる。"
  (let ((session (egg-mozc--clause-session
                  (egg-mozc--clause (car bunsetsu-list)))))
    (when (egg-mozc--session-open session)
      (let ((all (= (length bunsetsu-list)
                    (length (egg-mozc--segments
                             (egg-mozc--session-output session))))))
        (ignore-errors
          (if (and all (not abort))
              (egg-mozc--send session 'enter)
            ;; 変換中 → 入力中 → 空、の2段階で取り消す
            (egg-mozc--send session 'escape)
            (egg-mozc--send session 'escape))))
      (egg-mozc--close-session session))))

(defun egg-mozc-special-candidate (bunsetsu-list prev-b next-b _major type)
  "TYPE の候補を選ぶ。TYPE はキーに対応するコマンドの名前。
  `egg-hiragana'          ひらがな（M-h）
  `egg-katakana'          カタカナ（M-k）
  `egg-mozc-half-width'   半角（M-<）。かな・漢字なら読みの半角カタカナ
  `egg-mozc-full-width'   全角（M->）。数字や英字を全角に
隠している候補（`egg-mozc-hidden-candidate-regexp'）も選べる。"
  (let* ((clause (egg-mozc--clause (car bunsetsu-list)))
         (reading (egg-mozc--clause-reading clause)))
    (unless (egg-mozc--clause-candidates clause)
      (egg-mozc--fetch-candidates clause))
    (let* ((current (egg-mozc-bunsetsu-converted (car bunsetsu-list)))
           (wanted
            (pcase type
              ('egg-hiragana reading)
              ('egg-katakana (japanese-katakana reading))
              ('egg-mozc-half-width
               (let ((half (japanese-hankaku (japanese-katakana current))))
                 (if (equal half current)
                     (japanese-hankaku (japanese-katakana reading))
                   half)))
              ('egg-mozc-full-width (japanese-zenkaku current))))
           (i (and wanted (cl-position wanted (egg-mozc--clause-all clause)
                                       :test #'equal))))
      (and i
           (egg-mozc-decide-candidate bunsetsu-list (egg-mozc--reveal clause i)
                                      prev-b next-b)))))

;; 変換中のキー。M-h / M-k と同じしくみ（`egg-hiragana'）で、コマンド名が種類になる
(defalias 'egg-mozc-half-width 'egg-hiragana
  "変換中の文節を半角にする（半角カタカナ、半角数字など）。")
(defalias 'egg-mozc-full-width 'egg-hiragana
  "変換中の文節を全角にする（全角数字、全角英字など）。")
(with-eval-after-load 'egg-cnv
  (define-key egg-conversion-map "\M-<" 'egg-mozc-half-width)
  (define-key egg-conversion-map "\M->" 'egg-mozc-full-width))

;;; 単語登録

(defcustom egg-mozc-user-dict-program nil
  "Mozc のユーザー辞書を操作するプログラム（mozc_user_dict）。
nil なら `egg-mozc-libexec-directory' の mozc_user_dict を使う。"
  :type '(choice (const :tag "Default" nil) file)
  :group 'egg-mozc-backend)

(defcustom egg-mozc-part-of-speech-menu
  '(("名詞" . NOUN)
    ("固有名詞" . PROPER_NOUN)
    ("人名" . PERSONAL_NAME)
    ("姓" . FAMILY_NAME)
    ("名" . FIRST_NAME)
    ("組織" . ORGANIZATION_NAME)
    ("地名" . PLACE_NAME)
    ("名詞サ変（〜する）" . SA_IRREGULAR_CONJUGATION_NOUN)
    ("名詞形動（〜な）" . ADJECTIVE_VERBAL_NOUN)
    ("短縮よみ" . ABBREVIATION)
    ("サジェストのみ" . SUGGESTION_ONLY)
    ("副詞" . ADVERB)
    ("形容詞" . ADJECTIVE)
    ("動詞一段" . GROUP2_VERB)
    ("動詞カ行五段" . KA_GROUP1_VERB)
    ("動詞ガ行五段" . GA_GROUP1_VERB)
    ("動詞サ行五段" . SA_GROUP1_VERB)
    ("動詞タ行五段" . TA_GROUP1_VERB)
    ("動詞ナ行五段" . NA_GROUP1_VERB)
    ("動詞バ行五段" . BA_GROUP1_VERB)
    ("動詞マ行五段" . MA_GROUP1_VERB)
    ("動詞ラ行五段" . RA_GROUP1_VERB)
    ("動詞ワ行五段" . WA_GROUP1_VERB)
    ("動詞サ変" . SURU_GROUP3_VERB)
    ("記号" . SYMBOL)
    ("顔文字" . EMOTICON)
    ("抑制単語" . SUPPRESSION_WORD))
  "単語登録で選べる品詞（表示名 . Mozc の PosType の名前）。"
  :type '(alist :key-type string :value-type symbol)
  :group 'egg-mozc-backend)

(defun egg-mozc--user-dict (&rest args)
  "mozc_user_dict を ARGS で実行し、（成功したか . 出力）を返す。"
  (let ((program (or egg-mozc-user-dict-program
                     (expand-file-name "mozc_user_dict"
                                       (bound-and-true-p
                                        egg-mozc-libexec-directory)))))
    (with-temp-buffer
      (let* ((coding-system-for-read 'utf-8)
             (coding-system-for-write 'utf-8)
             (status (apply #'call-process program nil t nil args))
             (text (string-trim (buffer-string))))
        (cons (and (eql status 0) (string-prefix-p "OK" text)) text)))))

(defun egg-mozc-word-registration (_backend word reading)
  "WORD を読み READING で Mozc のユーザー辞書に登録する。
成功したら、Egg のメッセージ用に（品詞名 辞書名）を返す。"
  (let* ((word (substring-no-properties word))
         (reading (japanese-hiragana (substring-no-properties reading)))
         (label (menudiag-select
                 (list 'menu (format "%s（%s）の品詞:" word reading)
                       (mapcar #'car egg-mozc-part-of-speech-menu))))
         (pos (cdr (assoc label egg-mozc-part-of-speech-menu))))
    (unless pos
      (egg-error "egg-mozc: no part of speech was selected"))
    (pcase-let ((`(,ok . ,text)
                 (egg-mozc--user-dict "add" reading word (symbol-name pos))))
      (unless ok
        (egg-error "egg-mozc: word registration failed: %s" text))
      (list label "Mozc ユーザー辞書"))))

(defun egg-mozc-delete-word (reading word)
  "Mozc のユーザー辞書から、読み READING・単語 WORD の登録を削除する。"
  (interactive "s読み: \ns単語: ")
  (pcase-let ((`(,ok . ,text) (egg-mozc--user-dict "delete" reading word)))
    (message "%s" (if ok (format "%s（%s）を削除しました" word reading) text))))

(defun egg-mozc-list-words ()
  "Mozc のユーザー辞書の登録内容を表示する。"
  (interactive)
  (let ((text (cdr (egg-mozc--user-dict "list"))))
    (with-current-buffer (get-buffer-create "*Mozc user dictionary*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "辞書\tよみ\t単語\t品詞\tコメント\n" text "\n")
        (goto-char (point-min))
        (special-mode))
      (display-buffer (current-buffer)))))

;;; 入力メソッドの有効化

;;;###autoload
(defun egg-activate-mozc (&rest args)
  "Egg を Mozc バックエンドで有効にする（`register-input-method' から呼ばれる）。"
  (apply #'egg-mode (append args egg-mozc--backend-alist)))

(provide 'egg/mozc)
;;; egg/mozc.el ends here
