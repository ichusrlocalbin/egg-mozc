// Copyright (c) 2026 egg-mozc contributors
// SPDX-License-Identifier: MIT
//
// mozc_user_dict: Mozc のユーザー辞書をコマンドラインから操作する（Emacs / Egg 用）。
//
// 使い方:
//   mozc_user_dict add <よみ> <単語> <品詞> [コメント]
//   mozc_user_dict delete <よみ> <単語>
//   mozc_user_dict list
//   mozc_user_dict pos            （品詞の一覧）
//
// <品詞> は PosType の名前（NOUN、PERSONAL_NAME など）か番号。
// 単語は "Emacs" という名前の辞書に入れる（なければ作る）。
// 変更後は mozc_server に Reload を送って、すぐに変換に反映させる。
//
// 出力: 成功なら "OK ..."、失敗なら "ERROR ..."（終了コード 1）。

#include <cstdint>
#include <iostream>
#include <memory>
#include <string>

#include "absl/status/status.h"
#include "absl/status/statusor.h"
#include "absl/strings/numbers.h"
#include "absl/strings/string_view.h"
#include "client/client.h"
#include "client/user_dictionary/user_dictionary_storage.h"
#include "protocol/user_dictionary_storage.pb.h"

namespace {

using ::mozc::UserDictionaryStorage;
using ::mozc::user_dictionary::UserDictionary;

constexpr absl::string_view kDictionaryName = "Emacs";

int Fail(absl::string_view message) {
  std::cout << "ERROR " << message << std::endl;
  return 1;
}

bool ParsePos(absl::string_view str, UserDictionary::PosType* pos) {
  int n;
  if (absl::SimpleAtoi(str, &n)) {
    if (!UserDictionary::PosType_IsValid(n)) return false;
    *pos = static_cast<UserDictionary::PosType>(n);
    return true;
  }
  return UserDictionary::PosType_Parse(std::string(str), pos);
}

// 変更を mozc_server に反映させる。サーバーが動いていなければ何もしない
// （次に起動したときに読み込まれる）。
void ReloadServer() {
  std::unique_ptr<mozc::client::ClientInterface> client =
      mozc::client::ClientFactory::NewClient();
  if (client->PingServer()) {
    client->Reload();
  }
}

UserDictionary* FindOrCreateDictionary(UserDictionaryStorage& storage) {
  for (int i = 0; i < storage.dictionaries_size(); ++i) {
    if (storage.dictionaries(i).name() == kDictionaryName) {
      return storage.GetProto().mutable_dictionaries(i);
    }
  }
  absl::StatusOr<uint64_t> id = storage.CreateDictionary(kDictionaryName);
  if (!id.ok()) return nullptr;
  return storage.GetUserDictionary(*id);
}

int Load(UserDictionaryStorage& storage) {
  absl::Status s = storage.Load();
  // ファイルがまだない場合は空の辞書として続ける
  if (!s.ok() && storage.Exists().ok()) {
    return Fail(std::string("load failed: ") + std::string(s.message()));
  }
  return 0;
}

int Save(UserDictionaryStorage& storage) {
  if (!storage.Lock()) return Fail("cannot lock the user dictionary");
  absl::Status s = storage.Save();
  storage.UnLock();
  if (!s.ok()) return Fail(std::string("save failed: ") + std::string(s.message()));
  ReloadServer();
  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 2) {
    return Fail("usage: mozc_user_dict add|delete|list|pos ...");
  }
  const std::string cmd = argv[1];

  if (cmd == "pos") {
    const google::protobuf::EnumDescriptor* d =
        UserDictionary::PosType_descriptor();
    for (int i = 0; i < d->value_count(); ++i) {
      std::cout << d->value(i)->number() << "\t" << d->value(i)->name()
                << std::endl;
    }
    return 0;
  }

  UserDictionaryStorage storage(UserDictionaryStorage::GetDefaultUserDictionaryFileName());
  if (int r = Load(storage); r != 0) return r;

  if (cmd == "list") {
    for (const UserDictionary& dic : storage.GetProto().dictionaries()) {
      for (const UserDictionary::Entry& e : dic.entries()) {
        std::cout << dic.name() << "\t" << e.key() << "\t" << e.value() << "\t"
                  << UserDictionary::PosType_Name(e.pos()) << "\t" << e.comment()
                  << std::endl;
      }
    }
    return 0;
  }

  if (cmd == "add") {
    if (argc < 5) return Fail("usage: mozc_user_dict add YOMI WORD POS [COMMENT]");
    UserDictionary::Entry entry;
    entry.set_key(argv[2]);
    entry.set_value(argv[3]);
    UserDictionary::PosType pos;
    if (!ParsePos(argv[4], &pos)) return Fail("unknown POS");
    entry.set_pos(pos);
    if (argc >= 6) entry.set_comment(argv[5]);
    if (entry.key().empty()) return Fail("empty yomi");
    if (entry.value().empty()) return Fail("empty word");
    if (entry.key().size() > 300 || entry.value().size() > 300 ||
        entry.comment().size() > 300) {
      return Fail("too long");
    }
    for (const char c : entry.key() + entry.value() + entry.comment()) {
      if (c == '\t' || c == '\n' || c == '\r') return Fail("invalid character");
    }
    UserDictionary* dic = FindOrCreateDictionary(storage);
    if (dic == nullptr) return Fail("cannot create the dictionary");
    for (const UserDictionary::Entry& e : dic->entries()) {
      if (e.key() == entry.key() && e.value() == entry.value() &&
          e.pos() == entry.pos()) {
        std::cout << "OK already registered" << std::endl;
        return 0;
      }
    }
    if (UserDictionaryStorage::IsDictionaryFull(*dic)) {
      return Fail("the dictionary is full");
    }
    *dic->add_entries() = entry;
    if (int r = Save(storage); r != 0) return r;
    std::cout << "OK added" << std::endl;
    return 0;
  }

  if (cmd == "delete") {
    if (argc < 4) return Fail("usage: mozc_user_dict delete YOMI WORD");
    int removed = 0;
    for (UserDictionary& dic : *storage.GetProto().mutable_dictionaries()) {
      auto* entries = dic.mutable_entries();
      for (int i = entries->size() - 1; i >= 0; --i) {
        if (entries->Get(i).key() == argv[2] && entries->Get(i).value() == argv[3]) {
          entries->DeleteSubrange(i, 1);
          ++removed;
        }
      }
    }
    if (removed == 0) return Fail("not found");
    if (int r = Save(storage); r != 0) return r;
    std::cout << "OK deleted " << removed << std::endl;
    return 0;
  }

  return Fail("unknown command: " + cmd);
}
