;;; egg/wnnrpc.el --- WNN Support (low level interface) in Egg  -*- lexical-binding: nil; -*-
;;;                   Input Method Architecture

;; Copyright (C) 1999, 2000 Free Software Foundation, Inc
;;               2015 Hiroki Sato <hrs@allbsd.org>

;; Author: NIIBE Yutaka <gniibe@chroot.org>
;;         KATAYAMA Yoshio <kate@pfu.co.jp> ; Korean, Chinese support.

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
  (require 'egg-com)
  (defmacro wnn-file-string ()
    (string-as-unibyte (decode-coding-string "$B#W#n#n$N%U%!%$%k(B" 'euc-jp)))
  (defmacro wnn-const (c)
    "Macro for WNN constants."
    (cond ((eq c 'JS_VERSION)               0)
	  ((eq c 'JS_OPEN)                  1)
	  ((eq c 'JS_CLOSE)                 3)
	  ((eq c 'JS_CONNECT)               5)
	  ((eq c 'JS_DISCONNECT)            6)
	  ((eq c 'JS_ENV_EXIST)             7)
	  ((eq c 'JS_ENV_STICKY)            8)
	  ((eq c 'JS_ENV_UNSTICKY)          9)
	  ((eq c 'JS_KANREN)               17)
	  ((eq c 'JS_KANTAN_SHO)           18)
	  ((eq c 'JS_KANZEN_SHO)           19)
	  ((eq c 'JS_KANTAN_DAI)           20)
	  ((eq c 'JS_KANZEN_DAI)           21)
	  ((eq c 'JS_HINDO_SET)            24)
	  ((eq c 'JS_DIC_ADD)              33)
	  ((eq c 'JS_DIC_DELETE)           34)
	  ((eq c 'JS_DIC_USE)              35)
	  ((eq c 'JS_DIC_LIST)             36)
	  ((eq c 'JS_DIC_INFO)             37)
	  ((eq c 'JS_FUZOKUGO_SET)         41)
	  ((eq c 'JS_FUZOKUGO_GET)         48)
	  ((eq c 'JS_WORD_ADD)             49)
	  ((eq c 'JS_WORD_DELETE)          50)
	  ((eq c 'JS_WORD_SEARCH)          51)
	  ((eq c 'JS_WORD_SEARCH_BY_ENV)   52)
	  ((eq c 'JS_WORD_INFO)            53)
	  ((eq c 'JS_WORD_COMMENT_SET)     54)
	  ((eq c 'JS_PARAM_SET)            65)
	  ((eq c 'JS_PARAM_GET)            66)
	  ((eq c 'JS_MKDIR)                81)
	  ((eq c 'JS_ACCESS)               82)
	  ((eq c 'JS_WHO)                  83)
	  ((eq c 'JS_ENV_LIST)             85)
	  ((eq c 'JS_FILE_LIST_ALL)        86)
	  ((eq c 'JS_DIC_LIST_ALL)         87)
	  ((eq c 'JS_FILE_READ)            97)
	  ((eq c 'JS_FILE_WRITE)           98)
	  ((eq c 'JS_FILE_SEND)            99)
	  ((eq c 'JS_FILE_RECEIVE)        100)
	  ((eq c 'JS_HINDO_FILE_CREATE)   101)
	  ((eq c 'JS_DIC_FILE_CREATE)     102)
	  ((eq c 'JS_FILE_REMOVE)         103)
	  ((eq c 'JS_FILE_LIST)           104)
	  ((eq c 'JS_FILE_INFO)           105)
	  ((eq c 'JS_FILE_LOADED)         106)
	  ((eq c 'JS_FILE_LOADED_LOCAL)   107)
	  ((eq c 'JS_FILE_DISCARD)        108)
	  ((eq c 'JS_FILE_COMMENT_SET)    109)
	  ((eq c 'JS_FILE_PASSWORD_SET)   110)
	  ((eq c 'JS_FILE_STAT)           111)
	  ((eq c 'JS_KILL)                112)
	  ((eq c 'JS_HINSI_LIST)          114)
	  ((eq c 'JS_HINSI_NAME)          115)
	  ((eq c 'JS_HINSI_NUMBER)        116)
	  ((eq c 'JS_HINSI_DICTS)         117)
	  ((eq c 'JS_HINSI_TABLE_SET)     118)
	  ((eq c 'JS_ACCESS_ADD_HOST)         ?\xf00011)
	  ((eq c 'JS_ACCESS_ADD_USER)         ?\xf00012)
	  ((eq c 'JS_ACCESS_REMOVE_HOST)      ?\xf00013)
	  ((eq c 'JS_ACCESS_REMOVE_USER)      ?\xf00014)
	  ((eq c 'JS_ACCESS_ENABLE)           ?\xf00015)
	  ((eq c 'JS_ACCESS_DISABLE)          ?\xf00016)
	  ((eq c 'JS_ACCESS_GET_INFO)         ?\xf00017)
	  ((eq c 'JS_TEMPORARY_DIC_ADD)       ?\xf00021)
	  ((eq c 'JS_TEMPORARY_DIC_DELETE)    ?\xf00022)
	  ((eq c 'JS_AUTOLEARNING_WORD_ADD)   ?\xf00023)
	  ((eq c 'JS_SET_AUTOLEARNING_DIC)    ?\xf00024)
	  ((eq c 'JS_GET_AUTOLEARNING_DIC)    ?\xf00025)
	  ((eq c 'JS_IS_LOADED_TEMPORARY_DIC) ?\xf00026)
	  ((eq c 'JS_TEMPORARY_WORD_ADD)      ?\xf00027)
	  ((eq c 'JS_SET_HENKAN_ENV)          ?\xf00031)
	  ((eq c 'JS_GET_HENKAN_ENV)          ?\xf00032)
	  ((eq c 'JS_SET_HENKAN_HINSI)        ?\xf00033)
	  ((eq c 'JS_GET_HENKAN_HINSI)        ?\xf00034)
	  ((eq c 'JS_HENKAN_WITH_DATA)        ?\xf00035)
	  ((eq c 'JS_FI_DIC_ADD)              ?\xf00061)
	  ((eq c 'JS_FI_HINDO_FILE_CREATE)    ?\xf00062)
	  ((eq c 'JS_FI_KANREN)               ?\xf00065)
	  ((eq c 'JS_SET_FI_PRIORITY)         ?\xf00066)
	  ((eq c 'JS_OPTIMIZE_FI)             ?\xf00067)
	  ((eq c 'JS_HENKAN_IKEIJI)           ?\xf0006f)
	  ((eq c 'JS_LOCK)                    ?\xf00071)
	  ((eq c 'JS_UNLOCK)                  ?\xf00072)
	  ((eq c 'JS_FI_DIC_LIST)             ?\xf00081)
	  ((eq c 'JS_FI_DIC_LIST_ALL)         ?\xf00082)
	  ((eq c 'JS_FUZOKUGO_LIST)           ?\xf00083)

	  ((eq c 'JS_YOSOKU_INIT)                 ?\xf01001)
	  ((eq c 'JS_YOSOKU_FREE)                 ?\xf01002)
	  ((eq c 'JS_YOSOKU_YOSOKU)               ?\xf01003)
	  ((eq c 'JS_YOSOKU_TOROKU)               ?\xf01004)
	  ((eq c 'JS_YOSOKU_SELECTED_CAND)        ?\xf01005)
	  ((eq c 'JS_YOSOKU_DELETE_CAND)          ?\xf01006)
	  ((eq c 'JS_YOSOKU_CANCEL_LATEST_TOROKU) ?\xf01007)
	  ((eq c 'JS_YOSOKU_RESET_PRE_YOSOKU)     ?\xf01008)
	  ((eq c 'JS_YOSOKU_IKKATSU_TOROKU)       ?\xf01009)
	  ((eq c 'JS_YOSOKU_SAVE_DATALIST)        ?\xf0100a)
	  ((eq c 'JS_YOSOKU_INIT_TIME_KEYDATA)    ?\xf0100b)
	  ((eq c 'JS_YOSOKU_INIT_INPUTINFO)       ?\xf0100c)
	  ((eq c 'JS_YOSOKU_SET_USER_INPUTINFO)   ?\xf0100d)
	  ((eq c 'JS_YOSOKU_SET_TIMEINFO)         ?\xf0100e)
	  ((eq c 'JS_YOSOKU_STATUS)               ?\xf0100f)
	  ((eq c 'JS_YOSOKU_SET_PARAM)            ?\xf01010)
	  ((eq c 'JS_YOSOKU_IKKATSU_TOROKU_INIT)  ?\xf01011)
	  ((eq c 'JS_YOSOKU_IKKATSU_TOROKU_END)   ?\xf01012)
	  ((eq c 'JS_HENKAN_ASSOC)                ?\xf01013)

	  ((eq c 'JLIB_VERSION)       ?\x4003)
	  ((eq c 'JLIB_VERSION_WNN6)  ?\x4f00)
	  ((eq c 'JLIB_VERSION_WNN7)  ?\x4f01)
	  ((eq c 'JLIB_VERSION_WNN8)  ?\x4f02)

	  ((eq c 'WNN_C_LOCAL)            "!")
	  ((eq c 'WNN_FT_DICT_FILE)         1)
	  ((eq c 'WNN_FT_HINDO_FILE)        2)
	  ((eq c 'WNN_FILE_STRING)       (encode-coding-string
					  "$B#W#n#n$N%U%!%$%k(B" 'euc-jp))
	  ((eq c 'WNN_FILE_STRING_LEN)     16)
	  ((eq c 'WNN_PASSWD_LEN)          16)
	  ((eq c 'WNN_HOST_LEN)            16)
	  ((eq c 'WNN_UNIQ_LEN)            28)
	  ((eq c 'WNN_FILE_HEADER_LEN)    128)
	  ((eq c 'WNN_FILE_HEADER_PAD)     36)
	  ((eq c 'WNN_FILE_BODY_PAD)      116)
	  ((eq c 'WNN_ENVNAME_LEN)         32)
	  ((eq c 'WNN_MAX_ENV_OF_A_CLIENT) 32)
	  ((eq c 'WNN_MAX_DIC_OF_AN_ENV)   30)
	  ((eq c 'WNN_MAX_FILE_OF_AN_ENV)  60)

	  ((eq c 'WNN_ACK)                  0)
	  ((eq c 'WNN_NAK)                 -1)

	  ((eq c 'WNN_NO_EXIST)             1)
	  ((eq c 'WNN_OPENF_ERR)           16)
	  ((eq c 'WNN_JSERVER_DEAD)        70)
	  ((eq c 'WNN_BAD_VERSION)         73)
	  ((eq c 'WNN_FILE_READ_ERROR)     90)
	  ((eq c 'WNN_FILE_WRITE_ERROR)    91)
	  ((eq c 'WNN_INCORRECT_PASSWD)    94)
	  ((eq c 'WNN_FILE_IN_USE)         95)
	  ((eq c 'WNN_UNLINK)              96)
	  ((eq c 'WNN_FILE_CREATE_ERROR)   97)
	  ((eq c 'WNN_NOT_A_FILE)          98)
	  ((eq c 'WNN_INODE_CHECK_ERROR)   99)

	  ((eq c 'WNN_UD_DICT)              2)
	  ((eq c 'WNN_REV_DICT)             3)
	  ((eq c 'CWNN_REV_DICT)       ?\x103)
	  ((eq c 'BWNN_REV_DICT)       ?\x203)
	  ((eq c 'WNN_COMPACT_DICT)         5)
	  ((eq c 'WNN_FI_SYSTEM_DICT)       6)
	  ((eq c 'WNN_FI_USER_DICT)         7)
	  ((eq c 'WNN_FI_HINDO_FILE)        8)
	  ((eq c 'WNN_GROUP_DICT)           9)
	  ((eq c 'WNN_MERGE_DICT)          10)
	  ((eq c 'WNN_VECT_NO)             -1)
	  ((eq c 'WNN_VECT_BUNSETSU)        2)
	  ((eq c 'WNN_VECT_KANREN)          0)
	  ((eq c 'WNN_VECT_KANZEN)          1)
	  ((eq c 'WNN_VECT_KANTAN)          1))))

(defconst wnnrpc-error-message
  '((Japanese .
     [
      nil
      "$B%U%!%$%k$,B8:_$7$^$;$s(B"
      nil
      "$B%a%b%j(B allocation $B$G<:GT$7$^$7$?(B"
      nil
      "$B<-=q$G$O$"$j$^$;$s(B"
      "$BIQEY%U%!%$%k$G$O$"$j$^$;$s(B"
      "$BIUB08l%U%!%$%k$G$O$"$j$^$;$s(B"
      nil
      "$B<-=q%F!<%V%k$,0lGU$G$9(B"
      "$BIQEY%U%!%$%k$,;XDj$5$l$?<-=q$NIQEY%U%!%$%k$G$O$"$j$^$;$s(B"
      nil
      nil
      nil
      nil
      nil
      "$B%U%!%$%k$,%*!<%W%s$G$-$^$;$s(B"
      "$B@5$7$$IQEY%U%!%$%k$G$O$"$j$^$;$s(B"
      "$B@5$7$$IUB08l%U%!%$%k$G$O$"$j$^$;$s(B"
      "$BIUB08l$N8D?t(B, $B%Y%/%?D9$5$J$I$,B?2a$.$^$9(B"
      "$B$=$NHV9f$N<-=q$O;H$o$l$F$$$^$;$s(B"
      nil
      nil
      nil
      "$BIUB08l%U%!%$%k$NFbMF$,@5$7$/$"$j$^$;$s(B"
      "$B5?;wIJ;lHV9f$,0[>o$G$9(B(hinsi.data $B$,@5$7$/$"$j$^$;$s(B)"
      "$BL$Dj5A$NIJ;l$,A0C<IJ;l$H$7$FDj5A$5$l$F$$$^$9(B"
      "$BIUB08l%U%!%$%k$,FI$_9~$^$l$F$$$^$;$s(B"
      nil
      nil
      "$B<-=q$N%(%$%s%H%j$,B?2a$.$^$9(B"
      "$BJQ49$7$h$&$H$9$kJ8;zNs$,D92a$.$^$9(B"
      "$BIUB08l2r@ONN0h$,ITB-$7$F$$$^$9(B"
      nil
      "$B<!8uJdNN0h$,ITB-$7$F$$$^$9(B"
      "$B8uJd$,(B 1 $B$D$b:n$l$^$;$s$G$7$?(B"
      nil
      nil
      nil
      nil
      "$BFI$_$,D92a$.$^$9(B"
      "$B4A;z$,D92a$.$^$9(B"
      "$B;XDj$5$l$?<-=q$OEPO?2DG=$G$O$"$j$^$;$s(B"
      "$BFI$_$ND9$5$,(B 0 $B$G$9(B"
      "$B;XDj$5$l$?<-=q$O5U0z$-2DG=$G$O$"$j$^$;$s(B"
      "$B%j!<%I%*%s%j!<$N<-=q$KEPO?(B/$B:o=|$7$h$&$H$7$^$7$?(B"
      "$B4D6-$KB8:_$7$J$$<-=q$KEPO?$7$h$&$H$7$^$7$?(B"
      nil
      nil
      "$B%j!<%I%*%s%j!<$NIQEY$rJQ99$7$h$&$H$7$^$7$?(B"
      "$B;XDj$5$l$?C18l$,B8:_$7$^$;$s(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$B%a%b%j(B allocation $B$G<:GT$7$^$7$?(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$B2?$+$N%(%i!<$,5/$3$j$^$7$?(B"
      "$B%P%0$,H/@8$7$F$$$kLOMM$G$9(B"
      "$B%5!<%P$,;`$s$G$$$^$9(B"
      "allocation $B$K<:GT$7$^$7$?(B"
      "$B%5!<%P$H@\B3$G$-$^$;$s$G$7$?(B"
      "$BDL?.%W%m%H%3%k$N%P!<%8%g%s$,9g$C$F$$$^$;$s(B"
      "$B%/%i%$%"%s%H$N@8@.$7$?4D6-$G$O$"$j$^$;$s(B"
      nil
      nil
      nil
      nil
      nil
      "$B%G%#%l%/%H%j$r:n$k$3$H$,$G$-$^$;$s(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$B%U%!%$%k$rFI$_9~$`$3$H$,$G$-$^$;$s(B"
      "$B%U%!%$%k$r=q$-=P$9$3$H$,$G$-$^$;$s(B"
      "$B%/%i%$%"%s%H$NFI$_9~$s$@%U%!%$%k$G$O$"$j$^$;$s(B"
      "$B$3$l0J>e%U%!%$%k$rFI$_9~$`$3$H$,$G$-$^$;$s(B"
      "$B%Q%9%o!<%I$,4V0c$C$F$$$^$9(B"
      "$B%U%!%$%k$,FI$_9~$^$l$F$$$^$9(B"
      "$B%U%!%$%k$,:o=|$G$-$^$;$s(B"
      "$B%U%!%$%k$,:n@.=PMh$^$;$s(B"
      "WNN $B$N%U%!%$%k$G$"$j$^$;$s(B"
      "$B%U%!%$%k$N(B inode $B$H(B FILE_UNIQ $B$r0lCW$5$;$k;v$,$G$-$^$;$s(B"
      "$BIJ;l%U%!%$%k$,Bg$-2a$.$^$9(B"
      "$BIJ;l%U%!%$%k$,Bg$-2a$.$^$9(B"
      "$BIJ;l%U%!%$%k$,B8:_$7$^$;$s(B"
      "$BIJ;l%U%!%$%k$NFbMF$,4V0c$C$F$$$^$9(B"
      nil
      "$BIJ;l%U%!%$%k$,FI$_9~$^$l$F$$$^$;$s(B"
      "$BIJ;lL>$,4V0c$C$F$$$^$9(B"
      "$BIJ;lHV9f$,4V0c$C$F$$$^$9(B"
      nil
      "$B$=$NA`:n$O%5%]!<%H$5$l$F$$$^$;$s(B"
      "$B%Q%9%o!<%I$NF~$C$F$$$k%U%!%$%k$,%*!<%W%s$G$-$^$;$s(B"
      "uumrc $B%U%!%$%k$,B8:_$7$^$;$s(B"
      "uumrc $B%U%!%$%k$N7A<0$,8m$C$F$$$^$9(B"
      "$B$3$l0J>e4D6-$r:n$k$3$H$O$G$-$^$;$s(B"
      "$B$3$N%/%i%$%"%s%H$,FI$_9~$s$@%U%!%$%k$G$"$j$^$;$s(B"
      "$B<-=q$KIQEY%U%!%$%k$,$D$$$F$$$^$;$s(B"
      "$B%Q%9%o!<%I$N%U%!%$%k$,:n@.=PMh$^$;$s(B"
      ])
    (Chinese-GB .
     [
      nil
      "$AND<~2;4fTZ(B"
      nil
      "$ADZ4f(Balloc$AJ'0\(B"
      nil
      "$A2;JGWV5d(B"
      "$A2;JGF56HND<~(B"
      "$A2;JGND7(ND<~(B"
      nil
      "$AWV5d1m8qBz(B"
      "$AF56HND<~#:2;JGV86(5DWV5d5DF56HND<~(B"
      nil
      nil
      nil
      nil
      nil
      "$AND<~2;D\4r?*(B"
      "$A2;JGU}H75DF56HND<~(B"
      "$A2;JGU}H75DND7(ND<~(B"
      "$A8=JtSo5D8vJ}!"OrA?3$6H5H3,9}(B"
      "$AUb8v:EBk5DWV5d!"C;SPJ9SC(B"
      nil
      nil
      nil
      "$AND7(ND<~5DDZH]2;U}H7(B"
      "$APiDb4JPT:EBkRl3#(Bcixing.data$A2;U}H7(B"
      "$AN46(Re5D4JPT!"6(ReAKG06K4JPT(B"
      "$AND7(ND<~2;D\6AH!(B"
      nil
      nil
      "$AWV5d5DOnJ}3,9}(B"
      "$A1d;;:sWV7{4.5D3$6H3,9}(B"
      "$A8=JtSo=bNvSr2;9;(B"
      nil
      "$A4N:n29Sr2;9;(B"
      "$A:n29(B 1$A8vR2C;SP(B"
      nil
      nil
      nil
      nil
      "$A6ARt3$6H3,9}(B"
      "$A::WV3$6H3,9}(B"
      "$AV86(5DWV5d!"2;D\5GB<(B"
      "$A6ARt5D3$6HJG(B 0"
      "$AV86(5DWV5d!"2;D\Df2i(B"
      "$AV;6A5DWV5d!"5GB<(B/$AO{3}AK(B"
      "$A;7>3VP2;4fTZ5DWV5d!"5GB<AK(B"
      nil
      nil
      "$AV;6A5DF56H!"1d8|AK(B"
      "$AV86(5D5%WV2;4fTZ(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$ADZ4f(Balloc$AJ'0\(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$ASP3v4m7"Iz(B"
      "$A:COsSP#b#u#g7"Iz(B"
      "server$AK@AK(B"
      "alloc$AJ'0\AK(B"
      "$A2;D\:M(Bserver$AA,=S(B"
      "$AM(PE9f3L5D0f1>2;7{(B"
      "$A2;JG#c#W#n#nSC;'Iz3I5D;7>3(B"
      nil
      nil
      nil
      nil
      nil
      "$AWSD?B<2;D\44=((B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$AND<~2;D\6AH!(B"
      "$AND<~2;D\P43v(B"
      "$A2;JG#c#W#n#nSC;'?I6AH!5DND<~(B"
      "$ARTIO5DND<~2;D\6AH!(B"
      "password$A2;6T(B"
      "$AND<~U}TZ6AH!(B"
      "$AND<~2;D\O{3}(B"
      "$AND<~C;SP44=(3v@4(B"
      "$A2;JG#c#W#n#n5DND<~(B"
      "$AND<~5D(BI-node$A:M(BFILE_UNIQ$A2;D\R;VB(B"
      "$A4JPTND<~L+4s(B"
      "$A4JPTND<~L+4s(B"
      "$A4JPTND<~2;4fTZ(B"
      "$A4JPTND<~5DDZH]2;6T(B"
      nil
      "$A4JPTND<~2;D\6AH!(B"
      "$A4JPTC{2;6T(B"
      "$A4JPT:EBk2;6T(B"
      nil
      "$AUb8v2YWw2;V'3V(B"
      "password$A5DJdHkND<~2;D\4r?*(B"
      "uumrc$AND<~2;4fTZ(B"
      "uumrc$AND<~5DPNJ=4mNs(B"
      "$ARTIO;7>32;D\44=((B"
      "$AUb8v#c#W#n#nSC;'!"6AH!5DND<~C;SP(B"
      "$AWV5d5DF56HND<~C;SP(B"
      "password$A5DND<~C;SP44=(3v@4(B"
      ])
    (Chinese-CNS .
     [
      nil
      "$(GEFG5DbGtGc(B"
      nil
      "$(GDyGt(Balloc$(GFBZu(B"
      nil
      "$(GDbQRGsL((B"
      "$(GDbQRs"PyEFG5(B"
      "$(GDbQREFNNEFG5(B"
      nil
      "$(GGsL(OPV*iH(B"
      "$(Gs"PyEFG5!3DbQRQ@LyN{GsL(N{s"PyEFG5(B"
      nil
      nil
      nil
      nil
      nil
      "$(GEFG5DbWdFTbd(B"
      "$(GDbQRF_m}N{s"PyEFG5(B"
      "$(GDbQRF_m}N{EFNNEFG5(B"
      "$(GOazhk#N{T6m0!#GWbXO[Pya+b>g4(B"
      "$(G]UT6f@n#N{GsL(!#JtH4KpFn(B"
      nil
      nil
      nil
      "$(GEFNNEFG5N{DyU)DbF_m}(B"
      "$(Gapsib$MLf@n#\,Z&(Bcixing.data$(GDbF_m}(B"
      "$(GF\LyexN{b$ML!#LyexD'P)j&b$ML(B"
      "$(GEFNNEFG5DbWd{tL=(B"
      nil
      nil
      "$(GGsL(N{bzm0b>g4(B"
      "$(G|H_PG[Gs\JHkN{O[Pyb>g4(B"
      "$(GOazhk#fXN5YQDbY\(B"
      nil
      "$(GH9OlfPYQDbY\(B"
      "$(GOlfP(B 1$(GT6D>JtH4(B"
      nil
      nil
      nil
      nil
      "$(G{tSvO[Pyb>g4(B"
      "$(GiGGsO[Pyb>g4(B"
      "$(GQ@LyN{GsL(!#DbWd`trg(B"
      "$(G{tSvN{O[PyQR(B 0"
      "$(GQ@LyN{GsL(!#DbWdXKQg(B"
      "$(GF7{tN{GsL(!#`trg(B/$(GV<XfD'(B"
      "$(Gt?h:DcDbGtGcN{GsL(!#`trgD'(B"
      nil
      nil
      "$(GF7{tN{s"Py!#|HJUD'(B"
      "$(GQ@LyN{^LGsDbGtGc(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(GDyGt(Balloc$(GFBZu(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(GH4Exrc`uFm(B"
      "$(GGob/H4$\$o$a`uFm(B"
      "server$(GH;D'(B"
      "alloc$(GFBZuD'(B"
      "$(GDbWdLO(Bserver$(G]YZY(B"
      "$(G]WOj]=a#N{NjF[Db\J(B"
      "$(GDbQR$]$q$h$hFnEBFmH)N{t?h:(B"
      nil
      nil
      nil
      nil
      nil
      "$(GDMFxrgDbWd^6Pz(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(GEFG5DbWd{tL=(B"
      "$(GEFG5DbWdlQEx(B"
      "$(GDbQR$]$q$h$hFnEBF+{tL=N{EFG5(B"
      "$(GEhD8N{EFG5DbWd{tL=(B"
      "password$(GDbhW(B"
      "$(GEFG5F_Gc{tL=(B"
      "$(GEFG5DbWdV<Xf(B"
      "$(GEFG5JtH4^6PzExKt(B"
      "$(GDbQR$C$W$h$hN{EFG5(B"
      "$(GEFG5N{(BI-node$(GLO(BFILE_UNIQ$(GDbWdD!S3(B"
      "$(Gb$MLEFG5E4DK(B"
      "$(Gb$MLEFG5E4DK(B"
      "$(Gb$MLEFG5DbGtGc(B"
      "$(Gb$MLEFG5N{DyU)DbhW(B"
      nil
      "$(Gb$MLEFG5DbWd{tL=(B"
      "$(Gb$MLGXDbhW(B"
      "$(Gb$MLf@n#DbhW(B"
      nil
      "$(G]UT6pgI"DbEEQ=(B"
      "password$(GN{rSD+EFG5DbWdFTbd(B"
      "cwnnrc$(GEFG5DbGtGc(B"
      "cwnnrc$(GEFG5N{J0H"rck((B"
      "$(GEhD8t?h:DbWd^6Pz(B"
      "$(G]UT6$C$W$h$hFnEB!#{tL=N{EFG5JtH4(B"
      "$(GGsL(N{s"PyEFG5JtH4(B"
      "password$(GN{EFG5JtH4^6PzExKt(B"
      ])
    (Korean .
     [
      nil
      "$(CH-@O@L(B $(CA8@gGOAv(B $(C>J=@4O4Y(B"
      nil
      "$(C8^8p8.(B alloc $(C?!<-(B $(C=GFPG_@>4O4Y(B"
      nil
      "$(C;g@|@L(B $(C>F4U4O4Y(B"
      "$(C:s55(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(C:N<S>n(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      nil
      "$(C;g@|(B $(CEW@L:m@L(B $(C2K(B $(CC!@>4O4Y(B"
      "$(CAvA$5H(B $(C;g@|@G(B $(C:s55(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      nil
      nil
      nil
      nil
      nil
      "$(CH-@O@;(B $(C?-(B $(C<v(B $(C>x@>4O4Y(B"
      "$(C8B4B(B $(C:s55(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(C8B4B(B $(C:N<S>n(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(C:N<S>n@G(B $(C09<v0!(B $(C3J9+(B $(C890E3*(B $(C:$EM@G(B $(C1f@L0!(B $(C3J9+(B $(C1i4O4Y(B"
      "$(C1W(B $(C9xH#@G(B $(C;g@|@:(B $(C;g?k5G0m(B $(C@VAv(B $(C>J=@4O4Y(B"
      nil
      nil
      nil
      "$(C:N<S>n(B $(CH-@O@G(B $(C3;?k@L(B $(C8BAv(B $(C>J=@4O4Y(B"
      "$(C0!;s(B $(CG0;g@G(B $(C9xH#0!(B $(CF2834O4Y(B. hinsi.data $(C0!(B $(C8BAv(B $(C>J=@4O4Y(B"
      "$(C9LA$@G@G(B $(CG0;g0!(B $(C@|4\(B $(CG0;g7N(B $(CA$@G5G>n(B $(C@V=@4O4Y(B"
      "$(C:N<S>n(B $(CH-@O@L(B $(C@PGtA.(B $(C@VAv(B $(C>J=@4O4Y(B"
      nil
      nil
      "$(C;g@|@G(B $(C?#F.8.0!(B $(C3J9+(B $(C89=@4O4Y(B"
      "$(C:/H/GO7A4B(B $(C9.@Z?-@L(B $(C3J9+(B $(C1i4O4Y(B"
      "$(C:N<S>n(B $(CGX<.(B $(C?5?*@L(B $(C:NA7GU4O4Y(B"
      nil
      "$(C4Y@=(B $(CHD:8(B $(C?5?*@L(B $(C:NA7GU4O4Y(B"
      "$(CHD:80!(B $(C>x@>4O4Y(B"
      nil
      nil
      nil
      nil
      "$(CGQ1[@L(B $(C3J9+(B $(C1i4O4Y(B"
      "$(CGQ@Z0!(B $(C3J9+(B $(C1i4O4Y(B"
      "$(CAvA$5H(B $(C;g@|@:(B $(C5n7O(B $(C:R0!4I@T4O4Y(B"
      "$(CGQ1[@G(B $(C1f@L0!(B 0 $(C@T4O4Y(B"
      "$(CAvA$5H(B $(C;g@|@:(B $(C?*B|A6(B $(C:R0!4I@T4O4Y(B"
      "$(C@P1b@|?k(B $(C;g@|?!(B $(C5n7O(B/$(C<R0E(B $(CGO7A0m(B $(CG_@>4O4Y(B"
      "$(CA8@gGOAv(B $(C>J4B(B $(C;g@|?!(B $(C5n7O(B $(CGO7A0m(B $(CG_@>4O4Y(B"
      nil
      nil
      "$(C@P1b@|?k(B $(C:s558&(B $(C0f=E(B $(CGO7A0m(B $(CG_@>4O4Y(B"
      "$(CAvA$5H(B $(C4\>n4B(B $(CA8@gGOAv(B $(C>J=@4O4Y(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(C8^8p8.(B alloc $(C?!(B $(C=GFPG_@>4O4Y(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(C?!7/0!(B $(C9_;}G_@>4O4Y(B"
      "$(C9v1W(B(Bug)$(C0!(B $(C9_;}G_@>4O4Y(B"
      "$(C<-9v(B(Server)$(C0!(B $(CAW>n(B $(C@V@>4O4Y(B"
      "alloc$(C?!(B $(C=GFPG_@>4O4Y(B"
      "$(C<-9v(B(Server) $(C?M(B $(CA"CKGR(B $(C<v(B $(C>x@>4O4Y(B"
      "$(CEk=E(B $(CGA7NEdD]@G(B $(C9vA/@L(B $(C8BAv(B $(C>J=@4O4Y(B"
      "$(CE,6s@L>HF.0!(B $(C;}<:GQ(B $(CH/0f@L(B $(C>F4U4O4Y(B"
      nil
      nil
      nil
      nil
      nil
      "$(C5p7:Ed8.8&(B $(C885i(B $(C<v(B $(C>x@>4O4Y(B"
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      nil
      "$(CH-@O(B $(C@P1b?!(B $(C=GFPG_@>4O4Y(B"
      "$(CH-@O(B $(C>21b?!(B $(C=GFPG_@>4O4Y(B"
      "$(CE,6s@L>HF.0!(B $(C@P>n(B $(C5e80(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(C4u(B $(C@L;s@G(B $(CH-@O@;(B $(C@P>n(B $(C5e81(B $(C<v(B $(C>x@>4O4Y(B"
      "$(CFP=:?v5e0!(B $(CF2834O4Y(B"
      "$(CH-@O@L(B $(C@PGtA.(B $(C@V@>4O4Y(B"
      "$(CH-@O@;(B $(C<R0EGR(B $(C<v(B $(C>x@>4O4Y(B"
      "$(CH-@O@;(B $(C@[<:GR(B $(C<v(B $(C>x@>4O4Y(B"
      "kWnn$(C@G(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(CH-@O@G(B I-node $(C?M(B FILE_UNIQ $(C8&(B $(C@OD!=CE3(B $(C<v(B $(C>x@>4O4Y(B"
      "$(CG0;g(B $(CH-@O@G(B $(CE)1b0!(B $(C3J9+(B $(CE.4O4Y(B"
      "$(CG0;g(B $(CH-@O@G(B $(CE)1b0!(B $(C3J9+(B $(CE.4O4Y(B"
      "$(CG0;g(B $(CH-@O@L(B $(CA8@gGOAv(B $(C>J=@4O4Y(B"
      "$(CG0;g(B $(CH-@O@G(B $(C3;?k@L(B $(CF2834O4Y(B"
      nil
      "$(CG0;g(B $(CH-@O@L(B $(C@PGtA.(B $(C@VAv(B $(C>J=@4O4Y(B"
      "$(CG0;g(B $(C@L8'@L(B $(CF2834O4Y(B"
      "$(CG0;g(B $(C9xH#0!(B $(CF2834O4Y(B"
      nil
      "$(C1W(B $(CA6@[@:(B $(CAv?x5GAv(B $(C>J=@4O4Y(B"
      "$(CFP=:?v5e0!(B $(C5i>n@V4B(B $(CH-@O@;(B $(C?-(B $(C<v(B $(C>x@>4O4Y(B"
      "uumrc $(C@L(B $(CA8@gGOAv(B $(C>J=@4O4Y(B"
      "uumrc $(C@G(B $(CG|=D@L(B $(CF2834O4Y(B"
      "$(C@L(B $(C@L;s(B $(CH/0f@;(B $(C@[<:GR(B $(C<v(B $(C>x@>4O4Y(B"
      "$(CE)6s@L>HF.0!(B $(C@P>n(B $(C5e80(B $(CH-@O@L(B $(C>F4U4O4Y(B"
      "$(C;g@|?!(B $(C:s55(B $(CH-@O@L(B $(CA8@gGOAv(B $(C>J=@4O4Y(B"
      "$(CFP=:?v5e(B $(CH-@O@;(B $(C@[<:GR(B $(C<v(B $(C>x@>4O4Y(B"
      ]))
  "Array of WNN error messages.  Indexed by error code.")

(defvar wnnrpc-timeout 10)

(defun wnnrpc-message-language (lang)
  (or (cdr (assq lang egg-message-language-alist)) lang))

(defun wnnrpc-get-error-message (errno)
  "Return error message string specified by ERRNO."
  (let ((msg (cdr (or (assq (wnnrpc-message-language egg-default-language)
			    wnnrpc-error-message)
		      (assq (wnnrpc-message-language its-current-language)
			    wnnrpc-error-message)
		      (assq 'Japanese wnnrpc-error-message)))))
    (or (and (< errno (length msg)) (aref msg errno))
	(format "#%d" errno))))

(defmacro wnnrpc-call-with-proc (proc vlist send-expr &rest receive-exprs)
  `(comm-call-with-proc ,proc
       ((zhuyin its-zhuyin)
	(comm-accept-timeout wnnrpc-timeout)
	,@vlist)
     ,send-expr ,@receive-exprs))

(defmacro wnnrpc-call-with-environment (env vlist send-expr &rest rcv-exprs)
  `(comm-call-with-proc (wnnenv-get-proc ,env)
       ((zhuyin its-zhuyin)
	(comm-accept-timeout wnnrpc-timeout)
	(env-id (wnnenv-get-env-id ,env))
	,@vlist)
     ,send-expr ,@rcv-exprs))

(defmacro wnnrpc-get-result (&rest body)
  `(let (result resulth)
     (comm-unpack (w w) resulth result)
     (cond ((and (= result 65535) (= resulth 65535))
           (setq result -1))
          ((= resulth (lsh (lsh resulth 16) -16))
           (setq result (+ (lsh resulth 16) result)))
          (t
           (error "overflow")))
     (if (< result 0)
       (progn
	 (comm-unpack (i) result)
	 (- result))
     ,@(or body '(result)))))

(defun wnnrpc-open-internal (proc version myhostname username)
  "Open the session.  Return 0 on success, error code on failure."
  (comm-call-with-proc proc ()
    (comm-format (u u s s)
		 (wnn-const JS_OPEN)
		 version myhostname username)
    (wnnrpc-get-result)))

(defun wnnrpc-open (proc myhostname username)
  "Open the session.  Return wnn4/wnn6/wnn7 or wnn8 on success, NIL on failure."
  (let ((type-list `((wnn8 . ,(wnn-const JLIB_VERSION_WNN8))
		     (wnn7 . ,(wnn-const JLIB_VERSION_WNN7))
		     (wnn6 . ,(wnn-const JLIB_VERSION_WNN6))
		     (wnn4 . ,(wnn-const JLIB_VERSION))))
	(result (- (wnn-const WNN_BAD_VERSION)))
	type version)
    (while (and type-list (= result (- (wnn-const WNN_BAD_VERSION))))
      (setq type (caar type-list)
	    version (cdar type-list)
	    type-list (cdr type-list)
	    result (wnnrpc-open-internal proc version myhostname username)))
    (if (zerop result)
	type
      result)))

(defun wnnrpc-connect (proc envname)
  "Establish new `connection' and make an environment.
Return the identitifation of the environment on success,
or negative error code on failure."
  (comm-call-with-proc proc ()
    (comm-format (u s) (wnn-const JS_CONNECT) envname)
    (wnnrpc-get-result)))

(defun wnnrpc-file-read (env filename)
  "Read the file FILENAME on the environment ENV
Return non-negative file ID on success, or negative error code on failure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u s) (wnn-const JS_FILE_READ) env-id filename)
    (wnnrpc-get-result)))

(defun wnnrpc-set-fuzokugo-file (env fid)
  "For PROC, on environment ENV-ID,
Set Fuzokugo file specified by FID.
Return 0 on success, negate-encoded error code on failure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i) (wnn-const JS_FUZOKUGO_SET) env-id fid)
    (wnnrpc-get-result)))

(defun wnnrpc-set-dictionary (env dic-id freq-id priority dic-rw freq-rw
				  dic-passwd freq-passwd reverse)
  "Set dictionary on server.
Return dictionary number on success, negate-encoded error code on faiulure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i i i u u s s u) (wnn-const JS_DIC_ADD)
		 env-id dic-id freq-id
		 priority
		 (if (numberp dic-rw) dic-rw (if dic-rw 0 1))
		 (if (numberp freq-rw) freq-rw (if freq-rw 0 1))
		 dic-passwd freq-passwd
		 (if reverse 1 0))
    (wnnrpc-get-result)))

(defun wnnrpc-set-fi-dictionary (env dic-id freq-id sys dic-rw freq-rw
				     dic-passwd freq-passwd)
  "Set FI dictionary on the server.
Return 0 on success, negate-encoded error code on faiulure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i i u u u s s) (wnn-const JS_FI_DIC_ADD)
		 env-id dic-id freq-id
		 (if sys
		     (wnn-const WNN_FI_SYSTEM_DICT)
		   (wnn-const WNN_FI_USER_DICT))
		 (if (numberp dic-rw) dic-rw (if dic-rw 0 1))
		 (if (numberp freq-rw) freq-rw (if freq-rw 0 1))
		 dic-passwd freq-passwd)
    (wnnrpc-get-result)))

(defun wnnrpc-get-autolearning-dic (env type)
  "Get id of auto learning dictionary on the server.
Return dictionary id + 1 on success, 0 on no dictionary, negate-encoded
error code on faiulure."
  (wnnrpc-call-with-environment env (result)
    (comm-format (u u u) (wnn-const JS_GET_AUTOLEARNING_DIC)
		 env-id type)
    (wnnrpc-get-result
      (comm-unpack (i) result)
      (1+ result))))

(defun wnnrpc-set-autolearning-dic (env type dic-id)
  "Set auto learning dictionary on the server.
Return 0 on success, negate-encoded error code on faiulure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u i) (wnn-const JS_SET_AUTOLEARNING_DIC)
		 env-id type dic-id)
    (wnnrpc-get-result)))

(defun wnnrpc-version (proc)
  "Return the version number of WNN server."
  (comm-call-with-proc proc (result)
    (comm-format (u) (wnn-const JS_VERSION))
    (comm-unpack (i) result)
    result))

(defun wnnrpc-access (env path mode)
  "Check the accessibility of file in the environment ENV.
Return 0 when the remote file (dictionary/frequency) of PATH on server
can be accessed in mode MODE.  Return Non-zero otherwise."
  (wnnrpc-call-with-environment env (result)
    (comm-format (u u u s) (wnn-const JS_ACCESS) env-id mode path)
    (comm-unpack (i) result)
    result))

(defun wnnrpc-mkdir (env path)
  "Create directory specified by PATH."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u s) (wnn-const JS_MKDIR) env-id path)
    (wnnrpc-get-result)))

(defun wnnrpc-writable-dic-type (env fi rw)
  (let ((server (wnnenv-get-server-type env)))
    (cond (fi                        (wnn-const WNN_FI_USER_DICT))
	  ((or (eq server 'cserver)
	       (eq server 'tserver)) (wnn-const CWNN_REV_DICT))
	  ((eq rw 3)                 (wnn-const WNN_GROUP_DICT))
	  ((eq rw 4)                 (wnn-const WNN_MERGE_DICT))
	  (t                         (wnn-const WNN_REV_DICT)))))

(defun wnnrpc-dic-file-create (env dicname type comment passwd hpasswd)
  "Create a dictionary on the server."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u s S s s u) (wnn-const JS_DIC_FILE_CREATE)
		 env-id dicname comment
		 passwd hpasswd type)
    (wnnrpc-get-result)))

(defun wnnrpc-hindo-file-create (env fi dic-id freqname comment passwd)
  "Create a frequency file on the server."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u s S s)
		 (if fi
		     (wnn-const JS_FI_HINDO_FILE_CREATE)
		   (wnn-const JS_HINDO_FILE_CREATE))
		 env-id dic-id freqname comment passwd)
    (wnnrpc-get-result)))

(defun wnnrpc-file-discard (env fid)
  "Discard a file specified by FID.  Call this for already-opened file
before remove and create new file."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i) (wnn-const JS_FILE_DISCARD)
		 env-id fid)
    (wnnrpc-get-result)))

(defun wnnrpc-file-remove (proc filename passwd)
  "Remove the file."
  (comm-call-with-proc proc ()
    (comm-format (u s s) (wnn-const JS_FILE_REMOVE)
		 filename (or passwd ""))
    (wnnrpc-get-result)))

(defun wnnrpc-set-conversion-parameter (env v)
  "Set conversion parameter."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i i i i i i i i i i i i i i i i i)
		 (wnn-const JS_PARAM_SET)
		 env-id
		 (aref v  0) (aref v  1) (aref v  2) (aref v  3) (aref v  4)
		 (aref v  5) (aref v  6) (aref v  7) (aref v  8) (aref v  9)
		 (aref v 10) (aref v 11) (aref v 12) (aref v 13) (aref v 14)
		 (aref v 15) (aref v 16))
    (wnnrpc-get-result)))

(defun wnnrpc-set-conversion-env-param (env mask v)
  "Set Wnn6 conversion parameter."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u i i i i i i i i i i i i i i i i i i)
		 (wnn-const JS_SET_HENKAN_ENV)
		 env-id mask
		 (aref v  0) (aref v  1) (aref v  2) (aref v  3) (aref v  4)
		 (aref v  5) (aref v  6) (aref v  7) (aref v  8) (aref v  9)
		 (aref v 10) (aref v 11) (aref v 12) (aref v 13) (aref v 14)
		 (aref v 15) (aref v 16) (aref v 17))
    (wnnrpc-get-result)))

(defun wnn7rpc-set-conversion-env-param (env mask v)
  "Set Wnn7 conversion parameter."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u i i i i i i i i i i i i i i i i i i i i i i i i)
                 (wnn-const JS_SET_HENKAN_ENV)
                 env-id mask
                 (aref v  0) (aref v  1) (aref v  2) (aref v  3) (aref v  4)
                 (aref v  5) (aref v  6) (aref v  7) (aref v  8) (aref v  9)
                 (aref v 10) (aref v 11) (aref v 12) (aref v 13) (aref v 14)
                 (aref v 15) (aref v 16) (aref v 17) 
		 ;; (aref v 18)
		 ;; (aref v 19)
                 ;; (aref v 20)
		 ;; (aref v 21)
		 ;; (aref v 22)
		 ;; (aref v 23))
		 0 10 0 0 0 0)
    (wnnrpc-get-result)))

(defun wnn7rpc-set-conversion-env-param-highbit (env maskh maskl v)
  "Set Wnn7 conversion parameter (use high bit mask)."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u w w i i i i i i i i i i i i i i i i i i i i i i i i)
                 (wnn-const JS_SET_HENKAN_ENV)
                 env-id maskh maskl
                 (aref v  0) (aref v  1) (aref v  2) (aref v  3) (aref v  4)
                 (aref v  5) (aref v  6) (aref v  7) (aref v  8) (aref v  9)
                 (aref v 10) (aref v 11) (aref v 12) (aref v 13) (aref v 14)
                 (aref v 15) (aref v 16) (aref v 17) (aref v 18) (aref v 19)
                 (aref v 20) (aref v 21) (aref v 22) (aref v 23))
    (wnnrpc-get-result)))

(defun wnnrpc-temporary-dic-loaded (env)
  "Ask to the server whether the temporary dictionary is loaded or not.
Return positive if loaded, zero if not, negative on failure."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_IS_LOADED_TEMPORARY_DIC)
		 env-id)
    (wnnrpc-get-result)))

(defun wnnrpc-temporary-dic-add (env reverse)
  "Add temporary dictionary on the server."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u) (wnn-const JS_TEMPORARY_DIC_ADD)
		 env-id (if reverse 1 0))
    (wnnrpc-get-result)))

(defun wnnrpc-receive-sho-bunsetsu-list (env n-bunsetsu)
  (let ((proc (wnnenv-get-proc env))
	slist
	end start jiritsugo-end dic-no entry freq right-now
	hinshi status status-backward kangovect evaluation
	result source fuzokugo)
    (while (> n-bunsetsu 0)
      (comm-unpack (i i i i i i i i i i i i)
		   end start jiritsugo-end
		   dic-no entry freq right-now hinshi
		   status status-backward kangovect evaluation)
      (setq slist
	    (cons
	     (wnn-bunsetsu-create env (1+ (- jiritsugo-end start))
				  dic-no entry freq right-now hinshi
				  status status-backward kangovect evaluation)
	     slist))
      (setq n-bunsetsu (1- n-bunsetsu)))
    (prog1
	(setq slist (nreverse slist))
      (while slist
	(comm-unpack (S S S) result source fuzokugo)
	(wnn-bunsetsu-set-converted (car slist) result)
	(wnn-bunsetsu-set-yomi (car slist) source)
	(wnn-bunsetsu-set-fuzokugo (car slist) fuzokugo)
	(setq slist (cdr slist))))))

(defun wnnrpc-receive-dai-bunsetsu-list (env n-dai separate)
  (let ((proc (wnnenv-get-proc env))
	n-bunstsu kanji-length dlist slist
	end start n-sho evaluation
	n retval)
    (comm-unpack (i i) n-bunstsu kanji-length)
    (while (> n-dai 0)
      (comm-unpack (i i i i) end start n-sho evaluation)
      (setq dlist (cons (cons n-sho evaluation) dlist)
	    n-dai (1- n-dai)))
    (setq dlist (nreverse dlist)
	  slist (wnnrpc-receive-sho-bunsetsu-list env n-bunstsu))
    (if (null separate)
	(prog1
	    slist
	  (while dlist
	    (setq n (caar dlist))
	    (while (> n 0)
	      (wnn-bunsetsu-set-dai-evaluation (car slist) (cdar dlist))
	      (wnn-bunsetsu-set-dai-continue (car slist) (> n 1))
	      (setq slist (cdr slist)
		    n (1- n)))
	    (setq dlist (cdr dlist))))
      (while dlist
	(setq retval (cons slist retval)
	      n (caar dlist))
	(while (> n 1)
	  (wnn-bunsetsu-set-dai-evaluation (car slist) (cdar dlist))
	  (wnn-bunsetsu-set-dai-continue (car slist) t)
	  (setq slist (cdr slist)
		n (1- n)))
	(wnn-bunsetsu-set-dai-evaluation (car slist) (cdar dlist))
	(wnn-bunsetsu-set-dai-continue (car slist)
				       (wnn-bunsetsu-connect-next (car slist)))
	(setq slist (prog1 (cdr slist) (setcdr slist nil))
	      dlist (cdr dlist)))
      (nreverse retval))))

(defun wnnrpc-renbunsetsu-conversion (env yomi hinshi fuzokugo v)
  "Convert YOMI string into Kanji.
HINSHI and FUZOKUGO are information of preceding bunsetsu."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u S i S i i i) (wnn-const JS_KANREN)
		 env-id yomi hinshi fuzokugo
		 (or v (wnn-const WNN_VECT_KANREN))
		 (if v (wnn-const WNN_VECT_KANREN) (wnn-const WNN_VECT_NO))
		 (wnn-const WNN_VECT_BUNSETSU))
     (wnnrpc-get-result
      (wnnrpc-receive-dai-bunsetsu-list env result nil))))

(defun wnnrpc-fi-renbunsetsu-conversion (env yomi hinshi fuzokugo v context)
  "Convert YOMI string into Kanji.
HINSHI and FUZOKUGO are information of preceding bunsetsu."
  (wnnrpc-call-with-environment env (result)
    (comm-format (u u S i S i i i i i i i S i i i i S) (wnn-const JS_FI_KANREN)
		 env-id yomi hinshi fuzokugo
		 (or v (wnn-const WNN_VECT_KANREN))
		 (if v (wnn-const WNN_VECT_KANREN) (wnn-const WNN_VECT_NO))
		 (wnn-const WNN_VECT_BUNSETSU)
		 (wnn-context-dic-no (car context))
		 (wnn-context-entry (car context))
		 (wnn-context-jirilen (car context))
		 (wnn-context-hinshi (car context))
		 (wnn-context-fuzokugo (car context))
		 (wnn-context-dic-no (nth 1 context))
		 (wnn-context-entry (nth 1 context))
		 (wnn-context-jirilen (nth 1 context))
		 (wnn-context-hinshi (nth 1 context))
		 (wnn-context-fuzokugo (nth 1 context)))
    (setq result (wnnrpc-get-result
		   (wnnrpc-receive-dai-bunsetsu-list env result nil)))
    (prog1
	result
      (unless (numberp result)
	(wnn-bunsetsu-set-fi-rel (car result)
				 (wnnrpc-get-fi-relation-data env))
	(while result
	  (wnn-bunsetsu-set-context (car result) context)
	  (setq result (cdr result)))))))

(defun wnnrpc-get-fi-relation-data (env)
  "Receive FI relation data from the server."
  (let ((proc (wnnenv-get-proc env))
	fi-dic dic entry offset num result)
    (comm-unpack (i) num)
    (while (> num 0)
      (comm-unpack (i i i i) fi-dic dic entry offset)
      (setq result (cons (vector fi-dic dic entry offset -2 -4) result)
	    num (1- num)))
    (nreverse result)))

(defun wnnrpc-tanbunsetsu-conversion (env yomi hinshi fuzoku v)
  ""
  (wnnrpc-call-with-environment env (kanji-length)
    (comm-format (u u S i S i i) (wnn-const JS_KANTAN_SHO)
		 env-id yomi hinshi fuzoku
		 (or v (wnn-const WNN_VECT_KANTAN))
		 (if v (wnn-const WNN_VECT_KANTAN) (wnn-const WNN_VECT_NO)))
    (wnnrpc-get-result
      (comm-unpack (u) kanji-length)	; ignore kanji-length
      (wnnrpc-receive-sho-bunsetsu-list env result))))

(defun wnnrpc-get-bunsetsu-candidates (env yomi hinshi fuzoku v)
  ""
  (wnnrpc-call-with-environment env (kanji-length)
    (comm-format (u u S i S i i) (wnn-const JS_KANZEN_SHO)
		 env-id yomi hinshi fuzoku
		 (or v (wnn-const WNN_VECT_KANZEN))
		 (if v (wnn-const WNN_VECT_KANZEN) (wnn-const WNN_VECT_NO)))
    (wnnrpc-get-result
      (comm-unpack (u) kanji-length)	; ignore kanji-length
      (mapcar (lambda (b)
		(wnn-bunsetsu-set-dai-continue b (wnn-bunsetsu-connect-next b))
		(list b))
	      (wnnrpc-receive-sho-bunsetsu-list env result)))))

(defun wnnrpc-daibunsetsu-conversion (env yomi hinshi fuzoku v)
  ""
  (wnnrpc-call-with-environment env (n-sho-bunsetsu kanji-size)
    (comm-format (u u S i S i i) (wnn-const JS_KANTAN_DAI)
		 env-id yomi hinshi fuzoku
		 (or v (wnn-const WNN_VECT_KANTAN))
		 (if v (wnn-const WNN_VECT_KANTAN) (wnn-const WNN_VECT_NO)))
    (wnnrpc-get-result
      (wnnrpc-receive-dai-bunsetsu-list env result nil))))

(defun wnnrpc-get-daibunsetsu-candidates (env yomi hinshi fuzoku v)
  ""
  (wnnrpc-call-with-environment env (n-sho-bunsetsu kanji-size)
    (comm-format (u u S i S i i) (wnn-const JS_KANZEN_DAI)
		 env-id yomi hinshi fuzoku
		 (or v (wnn-const WNN_VECT_KANZEN))
		 (if v (wnn-const WNN_VECT_KANZEN) (wnn-const WNN_VECT_NO)))
    (wnnrpc-get-result
      (wnnrpc-receive-dai-bunsetsu-list env result t))))

(defun wnnrpc-set-frequency (env dicno entry ima hindo)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u i i i i) (wnn-const JS_HINDO_SET)
		 env-id dicno entry ima hindo)
    (wnnrpc-get-result)))

(defun wnnrpc-set-fi-priority (env fi-rel)
  ""
  (wnnrpc-call-with-environment env ()
    (progn
      (comm-format (u u u) (wnn-const JS_SET_FI_PRIORITY)
		   env-id (length fi-rel))
      (while fi-rel
	(comm-format (i i i i i i)
		     (aref (car fi-rel) 0) (aref (car fi-rel) 1)
		     (aref (car fi-rel) 2) (aref (car fi-rel) 3)
		     (aref (car fi-rel) 4) (aref (car fi-rel) 5))
	(setq fi-rel (cdr fi-rel))))
    (wnnrpc-get-result)))

(defun wnnrpc-optimize-fi (env context)
  ""
  (wnnrpc-call-with-environment env (c)
    (progn
      (comm-format (u u u) (wnn-const JS_OPTIMIZE_FI)
		   env-id (length context))
      (while context
	(setq c (car context)
	      context (cdr context))
	(comm-format (i i i i i S)
		     (wnn-context-dic-no c)
		     (wnn-context-entry c)
		     (wnn-context-right-now c)
		     (wnn-context-freq c)
		     (wnn-context-length c)
		     (concat (wnn-context-converted c)
			     (wnn-context-fuzokugo c)))))
    (wnnrpc-get-result)))

(defun wnnrpc-close (proc)
  ""
  (comm-call-with-proc proc ()
    (comm-format (u) (wnn-const JS_CLOSE))
    (wnnrpc-get-result)))

(defun wnnrpc-env-exist (proc envname)
  ""
  (comm-call-with-proc proc (result)
    (comm-format (u s) (wnn-const JS_ENV_EXIST) envname)
    (comm-unpack (i) result)
    result))

(defun wnnrpc-make-env-sticky (env)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_ENV_STICKY) env-id)
    (wnnrpc-get-result)))

(defun wnnrpc-make-env-unsticky (env)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_ENV_UNSTICKY) env-id)
    (wnnrpc-get-result)))

(defun wnnrpc-disconnect (env)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_DISCONNECT) env-id)
    (wnnrpc-get-result)))

(defun wnnrpc-add-word (env dictionary yomi kanji comment hinshi initial-freq)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u S S S u u) (wnn-const JS_WORD_ADD)
		 env-id dictionary yomi kanji comment hinshi initial-freq)
    (wnnrpc-get-result)))

(defun wnnrpc-auto-learning (env type yomi kanji comment hinshi initial-freq)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u S S S u u) (wnn-const JS_AUTOLEARNING_WORD_ADD)
		 env-id type yomi kanji comment hinshi initial-freq)
    (wnnrpc-get-result)))

(defun wnnrpc-temporary-learning (env yomi kanji comment hinshi initial-freq)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u S S S u u) (wnn-const JS_AUTOLEARNING_WORD_ADD)
		 env-id yomi kanji comment hinshi initial-freq)
    (wnnrpc-get-result)))

(defun wnnrpc-get-dictionary-list-with-environment (env)
  ""
  (wnnrpc-call-with-environment env (n-dic)
    (comm-format (u u) (wnn-const JS_DIC_LIST) env-id)
    (comm-unpack (i) n-dic)
    (wnnrpc-receive-dictionary-list proc n-dic)))

(defun wnnrpc-get-fi-dictionary-list-with-environment (env mask)
  ""
  (wnnrpc-call-with-environment env (n-dic)
    (comm-format (u u u) (wnn-const JS_FI_DIC_LIST) env-id mask)
    (comm-unpack (i) n-dic)
    (wnnrpc-receive-dictionary-list proc n-dic)))

(defun wnnrpc-receive-dictionary-list (proc n-dic)
  (let (entry dic freq dic-mode freq-mode enable-flag nice
	rev comment dicname freqname dic-passwd freq-passwd
	type gosuu dic-local-flag freq-local-flag retval)
    (while (> n-dic 0)
      (comm-unpack (i i i i i i i i S s s s s i i i i)
		   entry dic freq dic-mode freq-mode enable-flag nice
		   rev comment dicname freqname dic-passwd freq-passwd
		   type gosuu dic-local-flag freq-local-flag)
      (setq retval (cons
		    (vector entry dic freq dic-mode freq-mode enable-flag nice
			    rev comment dicname freqname dic-passwd freq-passwd
			    type gosuu dic-local-flag freq-local-flag)
		    retval)
	    n-dic (1- n-dic)))
    (nreverse retval)))

(defsubst wnndic-get-id (dic) (aref dic 0))
(defsubst wnndic-get-comment (dic) (aref dic 8))
(defsubst wnndic-get-dictname (dic) (aref dic 9))

(defun wnnrpc-get-writable-dictionary-id-list (env)
  ""
  (wnnrpc-call-with-environment env (dic-list dic)
    (comm-format (u u i) (wnn-const JS_HINSI_DICTS) env-id -1)
    (wnnrpc-get-result
      (while (> result 0)
	(comm-unpack (i) dic)
	(setq dic-list (nconc dic-list (list dic))
	      result (1- result)))
      dic-list)))

(defun wnnrpc-get-hinshi-list (env dic name)
  ""
  (wnnrpc-call-with-environment env (hinshi hinshi-list str-size)
    (comm-format (u u u S) (wnn-const JS_HINSI_LIST) env-id dic name)
    (wnnrpc-get-result
      (comm-unpack (u) str-size)	; ignore
      (while (> result 0)
	(comm-unpack (S) hinshi)
	(setq hinshi-list (nconc hinshi-list (list hinshi))
	      result (1- result)))
      hinshi-list)))

(defun wnnrpc-hinshi-number (proc name)
  ""
  (wnnrpc-call-with-proc proc ()
    (comm-format (u S) (wnn-const JS_HINSI_NUMBER) name)
    (wnnrpc-get-result)))

(defun wnnrpc-get-conversion-parameter (env)
  ""
  (wnnrpc-call-with-environment env (n nsho p1 p2 p3 p4 p5 p6 p7 p8 p9
				     p10 p11 p12 p13 p14 p15)
    (comm-format (u u) (wnn-const JS_PARAM_GET) env-id)
    (wnnrpc-get-result
      (comm-unpack (i i  i i i i i  i i i i i  i i i i i)
		   n nsho p1 p2 p3 p4 p5 p6 p7 p8 p9
		   p10 p11 p12 p13 p14 p15)
      (vector n nsho p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12 p13 p14 p15))))

(defun wnnrpc-get-conversion-env-param (env)
  ""
  (wnnrpc-call-with-environment env (p1 p2 p3 p4 p5 p6 p7 p8 p9
				    p10 p11 p12 p13 p14 p15 p16 p17 p18)
    (comm-format (u u) (wnn-const JS_GET_HENKAN_ENV) env-id)
    (wnnrpc-get-result
      (comm-unpack (i i i i i i i i i i i i i i i i i i)
		   p1 p2 p3 p4 p5 p6 p7 p8 p9
		   p10 p11 p12 p13 p14 p15 p16 p17 p18)
      (vector p1 p2 p3 p4 p5 p6 p7 p8 p9
	      p10 p11 p12 p13 p14 p15 p16 p17 p18))))

(defun wnn7rpc-get-conversion-env-param (env)
  ""
  (wnnrpc-call-with-environment env (p1 p2 p3 p4 p5 p6 p7 p8 p9
                                    p10 p11 p12 p13 p14 p15 p16 p17 p18
                                    p19 p20 p21 p22 p23 p24)
    (comm-format (u u) (wnn-const JS_GET_HENKAN_ENV) env-id)
    (wnnrpc-get-result
      (comm-unpack (i i i i i i i i i i i i i i i i i i i i i i i i)
                   p1 p2 p3 p4 p5 p6 p7 p8 p9
                   p10 p11 p12 p13 p14 p15 p16
                   p17 p18 p19 p20 p21 p22 p23 p24)
      (vector p1 p2 p3 p4 p5 p6 p7 p8 p9
              p10 p11 p12 p13 p14 p15 p16 p17 p18
              p19 p20 p21 p22 p23 p24))))

(defun wnnrpc-file-loaded (proc path)
  ""
  (comm-call-with-proc proc (result)
    (comm-format (u s) (wnn-const JS_FILE_LOADED) path)
    (comm-unpack (i) result)
    result))

(defun wnnrpc-write-file (env fid filename)
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u s) (wnn-const JS_FILE_WRITE) env-id fid filename)
    (wnnrpc-get-result)))

(defun wnnrpc-get-fuzokugo-file (env)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_FUZOKUGO_GET) env-id)
    (wnnrpc-get-result)))

(defsubst wnnrpc-receive-file-list (proc)
  (let ((i 0)
	flist
	nfiles fid local ref-count type name)
    (comm-unpack (i) nfiles)
    (while (> nfiles 0)
      (comm-unpack (i i i i s) fid local ref-count type name)
      (setq flist (nconc flist (list (vector fid local ref-count type name)))
	    nfiles (1- nfiles)))
    flist))

(defun wnnrpc-get-file-list (proc)
  ""
  (comm-call-with-proc proc ()
    (comm-format (u) (wnn-const JS_FILE_LIST_ALL))
    (wnnrpc-receive-file-list proc)))

(defun wnnrpc-get-file-list-with-env (env)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_FILE_LIST) env-id)
    (wnnrpc-receive-file-list proc)))

(defun wnnrpc-file-attribute (env path)
  "3: dictionary, 4: hindo file, 5: fuzokugo-file"
  (wnnrpc-call-with-environment env (result)
    (comm-format (u u s) (wnn-const JS_FILE_STAT) env-id path)
    (comm-unpack (i) result)
    result))

(defun wnnrpc-get-file-info (env fid)
  ""
  (wnnrpc-call-with-environment env (name local ref-count type)
    (comm-format (u u u) (wnn-const JS_FILE_INFO) env-id fid)
    (wnnrpc-get-result
      (comm-unpack (s i i i) name local ref-count type)
      (vector name local ref-count type))))

(defmacro wnnrpc-receive-vector (n)
  `(let ((v (make-vector ,n -1))
	 (i 0)
	 j)
     (while (< i ,n)
       (comm-unpack (i) j)
       (aset v i j)
       (setq i (1+ i)))
     v))

(defun wnnrpc-who (proc)
  ""
  (comm-call-with-proc proc (who socket username hostname)
    (comm-format (u) (wnn-const JS_WHO))
    (wnnrpc-get-result
      (while (> result 0)
	(comm-unpack (i s s) socket username hostname)
	(setq who (nconc who
			 (list (vector socket username hostname
				       (wnnrpc-receive-vector
					(wnn-const WNN_MAX_ENV_OF_A_CLIENT)))))
	      result (1- result)))
      who)))

(defun wnnrpc-get-env-list (proc)
  (comm-call-with-proc proc (envs id name count fuzokugo dic-max)
    (comm-format (u) (wnn-const JS_ENV_LIST))
    (wnnrpc-get-result
      (while (> result 0)
	(comm-unpack (i s i i i) id name count fuzokugo dic-max)
	(setq envs (nconc envs
			  (list (vector id name count fuzokugo dic-max
					(wnnrpc-receive-vector
					 (wnn-const WNN_MAX_DIC_OF_AN_ENV))
					(wnnrpc-receive-vector
					 (wnn-const WNN_MAX_FILE_OF_AN_ENV)))))
	      result (1- result)))
	envs)))

(defun wnnrpc-kill (proc)
  ""
  (comm-call-with-proc proc (result)
    (comm-format (u) (wnn-const JS_KILL))
    (comm-unpack (i) result)
    result))

(defun wnnrpc-delete-dictionary (env dic)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u) (wnn-const JS_DIC_DELETE) env-id dic)
    (wnnrpc-get-result)))

(defun wnnrpc-set-flag-on-dictionary (env dic flag)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u) (wnn-const JS_DIC_USE) env-id dic flag)
    (wnnrpc-get-result)))

(defun wnnrpc-get-dictionary-list (proc)
  ""
  (wnnrpc-call-with-proc proc (n-dic)
    (comm-format (u) (wnn-const JS_DIC_LIST_ALL))
    (comm-unpack (i) n-dic)
    (wnnrpc-receive-dictionary-list proc n-dic)))

(defun wnnrpc-delete-word (env dic entry)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u) (wnn-const JS_WORD_DELETE) env-id dic entry)
    (wnnrpc-get-result)))

(defun wnnrpc-receive-word (proc yomi)
  (let (dic serial hinshi hindo right-now internal-hindo internal-right-now
	kanji comment l l1)
    (comm-unpack (i) dic)
    (while (>= dic 0)
      (comm-unpack (i i i i i i) serial hinshi hindo right-now
		   internal-hindo internal-right-now)
      (setq l (cons (vector dic serial hinshi hindo right-now
			    internal-hindo internal-right-now
			    yomi nil nil)
		    l))
      (comm-unpack (i) dic))
    (setq l (nreverse l)
	  l1 l)
    (while l1
      (comm-unpack (S S) kanji comment)
      (aset (car l1) 8 kanji)
      (aset (car l1) 9 comment)
      (setq l1 (cdr l1)))
    l))

(defun wnnrpc-search-word-in-dictionary (env dic yomi)
  ""
  (wnnrpc-call-with-environment env (n-entries len)
    (comm-format (u u u S) (wnn-const JS_WORD_SEARCH) env-id dic yomi)
    (comm-unpack (u u) n-entries len)	; ignore
    (wnnrpc-receive-word proc yomi)))

(defun wnnrpc-search-word (env yomi)
  ""
  (wnnrpc-call-with-environment env (n-entries len)
    (comm-format (u u S) (wnn-const JS_WORD_SEARCH_BY_ENV) env-id yomi)
    (comm-unpack (u u) n-entries len)	; ignore
    (wnnrpc-receive-word proc yomi)))

(defun wnnrpc-get-word-info (env dic entry)
  ""
  (wnnrpc-call-with-environment env (n-entries len yomi)
    (comm-format (u u u u) (wnn-const JS_WORD_INFO) env-id dic entry)
    (wnnrpc-get-result
      (comm-unpack (S) yomi)
      (comm-unpack (u u) n-entries len)	; ignore
      (wnnrpc-receive-word proc yomi))))

(defun wnnrpc-set-comment-on-word (env dic entry comment)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u S) (wnn-const JS_WORD_COMMENT_SET)
		 env-id dic entry comment)
    (wnnrpc-get-result)))

(defun wnnrpc-get-dictionary-info (env dic)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u) (wnn-const JS_DIC_INFO) env-id dic)
    (wnnrpc-get-result
      (wnnrpc-receive-dictionary-list proc 1))))

(defun wnnrpc-set-file-comment (env fid comment)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u S) (wnn-const JS_FILE_COMMENT_SET) env-id fid comment)
    (wnnrpc-get-result)))

(defun wnnrpc-hinshi-name (proc hinshi)
  ""
  (wnnrpc-call-with-proc proc ()
    (comm-format (u u) (wnn-const JS_HINSI_NAME) hinshi)
    (wnnrpc-get-result
      (comm-unpack (S) result)
      result)))

(defun wnnrpc-set-file-password (env fid which old new)
  "WHICH: 1: DIC, 2: HINDO, 3(0): Both"
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u s s) (wnn-const JS_FILE_PASSWORD_SET)
		 env-id fid which old new)
    (wnnrpc-get-result)))

(defun wnnrpc-set-hinshi-table (env dic hinshi-table)
  ""
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u S) (wnn-const JS_HINSI_TABLE_SET)
		 env-id dic hinshi-table)
    (wnnrpc-get-result)))

(defmacro wnnrpc-with-temp-buffer (&rest body)
  `(with-temp-buffer
     (let ((coding-system-for-read 'binary)
	   (coding-system-for-write 'binary))
       (set-buffer-multibyte nil)
       ,@body)))

(defmacro wnnrpc-with-write-file (filename error-handler &rest body)
  `(condition-case error
       (with-temp-file ,filename
	 (let ((coding-system-for-read 'binary)
	       (coding-system-for-write 'binary))
	   (set-buffer-multibyte nil)
	   ,@body))
     (file-error ,error-handler)))

(defmacro wnnrpc-terminate-current-command (errno)
  `(progn
     (comm-call-with-proc-1 proc ()
       (comm-format (i) (wnn-const WNN_NAK)))
     (- (wnn-const ,errno))))

(defun wnnrpc-get-local-filename (name)
  (if (and (string-match (wnn-const WNN_C_LOCAL) name)
	   (string= (substring name 0 (match-beginning 0)) wnn-system-name))
      (substring name (match-end 0))
    name))

;; <header> ::= (<type> <uniq> <uniq> <passwd>)
;; <uniq>   ::= string
;; <passwd> ::= string

(defun wnnrpc-scan-file-header ()
  (let ((proc nil)
	type uniq1 uniq2 passwd)
    (if (and (> (point-max) (wnn-const WNN_FILE_HEADER_LEN))
	     (equal (buffer-substring 1 (1+ (wnn-const WNN_FILE_STRING_LEN)))
		    (wnn-const WNN_FILE_STRING)))
	(progn
	  (goto-char (1+ (wnn-const WNN_FILE_STRING_LEN)))
	  (comm-unpack (i v v v)
		       type
		       uniq1 (wnn-const WNN_UNIQ_LEN)
		       uniq2 (wnn-const WNN_UNIQ_LEN)
		       passwd (wnn-const WNN_PASSWD_LEN))
	  (list type uniq1 uniq2 passwd)))))

(defun wnnrpc-get-file-header (filename)
  (wnnrpc-with-temp-buffer
    (if (null (file-readable-p filename))
	(list nil (make-string (wnn-const WNN_UNIQ_LEN) 0) "" "")
      (insert-file-contents filename nil 0 (wnn-const WNN_FILE_HEADER_LEN))
      (wnnrpc-scan-file-header))))

(defun wnnrpc-check-local-file (path &optional preserve)
  (let ((header (wnnrpc-get-file-header path)))
    (cond ((null header)
	   (- (wnn-const WNN_NOT_A_FILE)))
	  ((null (car header))
	   (if (file-exists-p path)
	       (- (wnn-const WNN_OPENF_ERR))
	     (- (wnn-const WNN_NO_EXIST))))
	  (t
	   (if (wnnrpc-check-inode header path)
	       header
	     (if preserve
		 (- (wnn-const WNN_INODE_CHECK_ERROR))
	       (wnnrpc-change-file-uniq header path)
	       (wnnrpc-check-local-file path t)))))))

(defsubst wnnrpc-get-inode (uniq)
  (+ (lsh (aref uniq 8) 24)
     (lsh (aref uniq 9) 16)
     (lsh (aref uniq 10) 8)
     (aref uniq 11)))

(defun wnnrpc-check-inode (header path)
  (let ((inode (nth 10 (file-attributes path))))
    (and inode (= inode (wnnrpc-get-inode (nth 1 header))))))

(defun wnnrpc-make-uniq (attributes)
  (wnnrpc-with-temp-buffer
    (let ((ctime (nth 6 attributes))
	  (ino (nth 10 attributes))
	  (devno (nth 11 attributes)))
      (if (numberp devno)
	  (comm-format (U i u V)
		       ctime devno ino
		       wnn-system-name (wnn-const WNN_HOST_LEN))
	;; Emacs 21 returns returns negative devno as 16 bits uint pair
	(comm-format (U U u V)
		     ctime (list (car devno) (cdr devno)) ino
		     wnn-system-name (wnn-const WNN_HOST_LEN)))
      (buffer-string))))

(defun wnnrpc-change-file-uniq (header path &optional new)
  (wnnrpc-with-write-file path
      nil
    (insert-file-contents path)
    (if (wnnrpc-scan-file-header)
	(let ((uniq (wnnrpc-make-uniq (file-attributes path))))
	  (goto-char (1+ (wnn-const WNN_FILE_STRING_LEN)))
	  (delete-region (point) (1+ (wnn-const WNN_FILE_HEADER_LEN)))
	  (comm-format (u v v v v)
		       (car header)
		       uniq (wnn-const WNN_UNIQ_LEN)
		       (if new uniq (nth 1 header)) (wnn-const WNN_UNIQ_LEN)
		       (nth 3 header) (wnn-const WNN_PASSWD_LEN)
		       "" (wnn-const WNN_FILE_HEADER_PAD))
	  t))))

(defun wnnrpc-check-passwd (proc passwd header)
  (let ((env-id -1))
    (unwind-protect
	(if (< (setq env-id (wnnrpc-connect proc "")) 0)
	    -1
	  (wnnrpc-call-with-environment (wnnenv-create proc env-id)
	      (file-id)
	    (comm-format (u u v) (wnn-const JS_FILE_SEND)
			 env-id
			 (nth 1 header) (wnn-const WNN_UNIQ_LEN))
	    (comm-unpack (i) file-id)
	    (if (>= file-id 0)
		(progn
		  (wnnrpc-get-result)	; ignore result code
		  (- (wnn-const WNN_FILE_IN_USE)))
	      (wnnrpc-get-result
		(comm-call-with-proc-1 proc ()
		  (comm-format (s B)
			       (concat wnn-system-name "!TEMPFILE")
			       (wnnrpc-make-dummy-dictionary header))
		  (wnnrpc-get-result
		    (let ((egg-fixed-euc (list egg-fixed-euc egg-fixed-euc)))
		      (wnnrpc-set-dictionary (wnnenv-create proc env-id)
					     result -1 1 t t
					     passwd "" nil))))))))
      (if (>= env-id 0)
	  (wnnrpc-disconnect (wnnenv-create proc env-id))))))

(defun wnnrpc-make-dummy-dictionary (header)
  (wnnrpc-with-temp-buffer
    (comm-format (v u v v v v u v)
		 (wnn-const WNN_FILE_STRING) (wnn-const WNN_FILE_STRING_LEN)
		 (wnn-const WNN_FT_DICT_FILE)
		 (nth 1 header) (wnn-const WNN_UNIQ_LEN)
		 (nth 1 header) (wnn-const WNN_UNIQ_LEN)
		 (nth 3 header) (wnn-const WNN_PASSWD_LEN)
		 "" (wnn-const WNN_FILE_HEADER_PAD)
		 (wnn-const WNN_REV_DICT)
		 "" (wnn-const WNN_FILE_BODY_PAD))
    (buffer-string)))

(defun wnnrpc-file-loaded-local (proc path &optional preserve)
  ""
  (let ((header (wnnrpc-check-local-file path preserve)))
    (if (numberp header)
	-1
      (comm-call-with-proc proc (result)
	(comm-format (u v) (wnn-const JS_FILE_LOADED_LOCAL)
		     (nth 1 header) (wnn-const WNN_UNIQ_LEN))
	(comm-unpack (i) result)
	result))))

(defun wnnrpc-file-receive (env fid local-filename)
  ""
  (condition-case err
      (wnnrpc-call-with-environment env (filename)
	(comm-format (u u u) (wnn-const JS_FILE_RECEIVE)
		     env-id fid)
	(comm-unpack (s) filename)
	(if (null local-filename)
	    (setq local-filename (wnnrpc-get-local-filename filename)))
	(let ((header (wnnrpc-get-file-header local-filename))
	      contents)
	  (if (null header)
	      (wnnrpc-terminate-current-command WNN_NOT_A_FILE)
	    (comm-call-with-proc-1 proc ()
	      (comm-format (u v) (wnn-const WNN_ACK)
			   (nth 1 header) (wnn-const WNN_UNIQ_LEN)))
	    (wnnrpc-get-result
	      (cond
	       ((= result 0) 0)
	       ((null (file-writable-p local-filename))
		(wnnrpc-terminate-current-command WNN_FILE_WRITE_ERROR))
	       (t
		(wnnrpc-with-write-file local-filename
		    (- (wnn-const WNN_FILE_WRITE_ERROR))
		  (comm-call-with-proc proc ()
		    (comm-format (u) (wnn-const WNN_ACK))
		    (comm-unpack (B) contents))
		  (insert contents)
		  (if (= result 2)
		      (insert-file-contents local-filename nil (1- (point))))
		  (with-current-buffer (process-buffer proc)
		    (wnnrpc-get-result)))))))))
    ((quit error)
     (wnnrpc-call-with-environment env ()
       (comm-format (i) (wnn-const WNN_NAK)))
     (signal (car err) (cdr err)))))

(defun wnnrpc-file-send (env filename)
  ""
  (let ((header (wnnrpc-check-local-file filename)))
    (if (numberp header)
	header
      (condition-case err
	  (wnnrpc-call-with-environment env (file-id)
	    (comm-format (u u v) (wnn-const JS_FILE_SEND)
			 env-id
			 (nth 1 header) (wnn-const WNN_UNIQ_LEN))
	    (comm-unpack (i) file-id)
	    (if (>= file-id 0)
		(wnnrpc-get-result
		  (wnnenv-set-client-file env filename)
		  file-id)
	      (wnnrpc-get-result
		(comm-call-with-proc-1 proc ()
		  (comm-format (s B)
			       (concat wnn-system-name "!" filename)
			       (wnnrpc-with-temp-buffer
				 (insert-file-contents filename)
				 (buffer-string)))
		  (wnnrpc-get-result
		    (wnnenv-set-client-file env filename)
		    result)))))
	((quit error)
	 (wnnrpc-call-with-environment env ()
	   (comm-format (s B B B B B B) "" "" "" "" "" "" ""))
	 (signal (car err) (cdr err)))))))

(defun wnnrpc-file-remove-client (proc name passwd)
  (let (header)
    (cond
     ((/= (wnnrpc-file-loaded-local proc name) -1)
      (- (wnn-const WNN_FILE_IN_USE)))
     ((null (file-readable-p name))
      (- (wnn-const WNN_FILE_READ_ERROR)))
     ((null (numberp (car (setq header (wnnrpc-get-file-header name)))))
      (- (wnn-const WNN_NOT_A_FILE)))
     ((< (wnnrpc-check-passwd proc passwd header) 0)
      (- (wnn-const WNN_INCORRECT_PASSWD)))
     (t
      (condition-case nil
	  (progn
	    (delete-file name)
	    0)
	(error (- (wnn-const WNN_UNLINK))))))))

(defun wnnrpc-dic-file-create-client (env dicname type comment passwd hpasswd)
  (if (and (null (file-exists-p dicname))
	   (file-writable-p dicname)
	   (or (eq type (wnn-const WNN_REV_DICT))
	       (eq type (wnn-const CWNN_REV_DICT))
	       (eq type (wnn-const BWNN_REV_DICT))
	       (eq type (wnn-const WNN_UD_DICT))
	       (and (or (wnnenv-is-wnn6 env) (wnnenv-is-wnn7 env) (wnnenv-is-wnn8 env))
		    (eq type (wnn-const WNN_FI_USER_DICT))))
	   (wnnrpc-create-and-move-to-client env nil dicname type
					     comment passwd hpasswd))
      0
    (- (wnn-const WNN_FILE_CREATE_ERROR))))


(defun wnnrpc-hindo-file-create-client (env fi dic-id freqname comment passwd)
  (if (and (null (file-exists-p freqname))
	   (file-writable-p freqname)
	   (wnnrpc-create-and-move-to-client env dic-id freqname fi
					     comment passwd nil))
      0
    (- (wnn-const WNN_FILE_CREATE_ERROR))))

(defun wnnrpc-make-temp-name (env)
  (let ((n 0)
	(temp-form "usr/temp"))
    (while (= (wnnrpc-access env (concat temp-form (number-to-string n)) 0) 0)
      (setq n (1+ n)))
    (concat temp-form (number-to-string n))))

(defun wnnrpc-create-and-move-to-client (env dic-id filename type
					     comment passwd hpasswd)
  (let ((tempfile (wnnrpc-make-temp-name env))
	(created -1)
	(fid -1))
    (unwind-protect
	(progn
	  (if (numberp type)
	      (setq created (wnnrpc-dic-file-create env tempfile type
						    comment passwd hpasswd))
	    (setq created (wnnrpc-hindo-file-create env type dic-id tempfile
						    comment passwd)))
	  (if (and (>= created 0)
		   (>= (setq fid (wnnrpc-file-read env tempfile)) 0)
		   (>= (wnnrpc-file-receive env fid filename) 0))
	      (wnnrpc-change-file-uniq (wnnrpc-get-file-header filename)
				       filename t)
	    (condition-case nil (delete-file filename) (error))
	    nil))
      (if (>= fid 0)
	  (wnnrpc-file-discard env fid))
      (if (>= created 0)
	  (wnnrpc-file-remove (wnnenv-get-proc env) tempfile passwd)))))

(defun wnnrpc-read-passwd-file (filename)
  (cond
   ((null filename) "")
   ((null (file-readable-p filename)) (- (wnn-const WNN_FILE_READ_ERROR)))
   (t
    (wnnrpc-with-temp-buffer
      (insert-file-contents filename nil 0 (1- (wnn-const WNN_PASSWD_LEN)))
      (goto-char 1)
      (if (and (search-forward-regexp "[\0\n]" nil 0)
	       (= (preceding-char) 0))
	  (backward-char))
      (buffer-substring 1 (point))))))

;;; egg/wnnrpc.el ends here.

;;;
;;; Wnn7 new function:
;;;   Input Prediction
;;;
;;;
(defun wnn7rpc-yosoku-init (env)
  "Initialize input prediction function"
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_INIT) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-free (env)
  "Free input prediction function area from server."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_FREE) env-id)
    (wnnrpc-get-result)))
(defun wnn7rpc-yosoku-yosoku (env moji)
  "Execute input prediction."
  (wnnrpc-call-with-environment env (candnum len kouho kouho-list)
    (comm-format (u u E) (wnn-const JS_YOSOKU_YOSOKU) env-id moji)
    (wnnrpc-get-result
      (comm-unpack (i) candnum)
      (while (> candnum 0)
       (comm-unpack (u s) len kouho)
       (setq kouho (decode-coding-string kouho 'euc-jp))
       (setq kouho-list (nconc kouho-list (list kouho))
             candnum (1- candnum)))
      kouho-list)))

(defun wnn7rpc-yosoku-toroku (env bun-suu yosoku-bunsetsu)
  "Register the input prediction candidate."
  (wnnrpc-call-with-environment env ()
    (progn
      (comm-format (u u u) (wnn-const JS_YOSOKU_TOROKU) env-id bun-suu)
      (while yosoku-bunsetsu
       (comm-format (E u E u u)
                    (aref (car yosoku-bunsetsu) 0)
                    (aref (car yosoku-bunsetsu) 1)
                    (aref (car yosoku-bunsetsu) 2)
                    (aref (car yosoku-bunsetsu) 3)
                    (aref (car yosoku-bunsetsu) 4))
       (setq yosoku-bunsetsu (cdr yosoku-bunsetsu))))
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-selected-cand (env selectpos)
  "Select the input prediction candidate."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u) (wnn-const JS_YOSOKU_SELECTED_CAND)
                env-id selectpos)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-delete-cand (env selectpos)
  "Delete the input prediction candidate."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u) (wnn-const JS_YOSOKU_DELETE_CAND)
                env-id selectpos)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-cancel-latest-toroku (env)
  "Cancel the latest registered word."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_CANCEL_LATEST_TOROKU) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-reset-pre-yosoku (env)
  "Clear the connection information for the latest registered word."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_RESET_PRE_YOSOKU) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-ikkatsu-toroku (env torokustr)
  "Register the input prediction candidate with phrase analysis."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u S) (wnn-const JS_YOSOKU_IKKATSU_TOROKU)
                env-id torokustr)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-save-datalist (env)
  "Save the input prediction data in data file."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_SAVE_DATALIST) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-init-time-keydata (env)
  "Initialize input efficiency data about inputed key."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_INIT_TIME_KEYDATA) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-init-inputinfo (env)
  "Initialize input efficiency data about input time."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u) (wnn-const JS_YOSOKU_INIT_INPUTINFO) env-id)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-set-user-inputinfo (env allkey userkey yosokuselect)
  "Set user input information to the input efficiency data."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u) (wnn-const JS_YOSOKU_SET_USER_INPUTINFO)
                env-id allkey
                (if yosokuselect
                    (logior userkey ?\x8000)
                  userkey))
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-set-timeinfo (env yosokuselect throughyosoku inputtime
                                      keylen)
  "Set input-time information to the input efficiency data."
  (wnnrpc-call-with-environment env ()
    (comm-format (u u u u u u) (wnn-const JS_YOSOKU_SET_TIMEINFO)
                env-id yosokuselect throughyosoku inputtime keylen)
    (wnnrpc-get-result)))

(defun wnn7rpc-yosoku-status (env)
  "Get input efficiency information."
  (wnnrpc-call-with-environment env (totalrod totalallkey totaluserkey
                                    totalrot totalalltime totalusertime
                                    stmday sthour stmin ltmday lthour ltmin
                                    totalroykinput totalallykkey nowrod
                                    nowallkey nowuserkey nowrot nowalltime
                                    nowusertime timeperonekey)
    (comm-format (u u) (wnn-const JS_YOSOKU_STATUS) env-id)
    (comm-unpack (i) totalrod)
    (if (< totalrod 0)
       totalrod
      (comm-unpack (u u u u u u u u u u u u u u u u u u u u)
                  totalallkey totaluserkey
                  totalrot totalalltime totalusertime
                  stmday sthour stmin ltmday lthour ltmin
                  totalroykinput totalallykkey
                  nowrod nowallkey nowuserkey nowrot nowalltime nowusertime
                  timeperonekey)
      (vector totalrod totalallkey totaluserkey totalrot totalalltime
             totalusertime stmday sthour stmin ltmday lthour ltmin
             totalroykinput totalallykkey nowrod nowallkey nowuserkey
             nowrot nowalltime nowusertime timeperonekey))))

;;;
;;; Wnn7 new function:
;;;   association translation
;;;
(defun wnn7rpc-assoc-with-data (env yomi hinsi fuzokugo v
                                  jilihin yomi_org jililen yomilen kanjilen
                                  real_kanjilen)
  "Convert YOMI string into Kanji with association."
  (wnnrpc-call-with-environment env (kanji-length)
       (comm-format (u u S i S i i u S i i i i) (wnn-const JS_HENKAN_ASSOC)
                    env-id yomi hinsi fuzokugo
                    (or v (wnn-const WNN_VECT_KANZEN))
                    (if v (wnn-const WNN_VECT_KANZEN) (wnn-const WNN_VECT_NO))
                    jilihin yomi_org jililen yomilen kanjilen real_kanjilen)
       (wnnrpc-get-result
        (comm-unpack (u) kanji-length) ; ignore kanji-length
        (mapcar (lambda (b)
                  (wnn7-bunsetsu-set-dai-continue b
                                                  (wnn7-bunsetsu-connect-next b))
                  (list b))
                (wnn7rpc-receive-sho-bunsetsu-list env result)))))


(defun wnn7rpc-set-henkan-hinshi (env mode nhinshi hlist)
  ""
  (wnnrpc-call-with-environment env ()
     (progn
       (comm-format (u u i i) (wnn-const JS_SET_HENKAN_HINSI)
                   env-id mode nhinshi)
       (while hlist
        (comm-format (u) (car hlist))
        (setq hlist (cdr hlist))))
     (wnnrpc-get-result)))
