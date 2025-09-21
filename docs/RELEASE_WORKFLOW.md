# Release Workflow - SyncLogger

dev環境からrelease環境への反映手順書

## ブランチ戦略

### devブランチ（開発環境）
```
📁 dev
├── addons/synclogger/      # メインアドオン
├── addons/gut/            # テストフレームワーク
├── tests/                 # テストスイート
├── docs/                  # 開発ドキュメント
├── sample_receiver.*      # サンプルレシーバー
├── demo_logger_integration.* # デモファイル
└── project.godot          # 完全なプロジェクト設定
```

### releaseブランチ（配布環境）
```
📁 release
├── addons/synclogger/      # メインアドオンのみ
├── sample_receiver.*      # サンプルレシーバー
├── README.md              # 英語版ドキュメント
├── README_ja.md           # 日本語版ドキュメント
├── LICENSE                # ライセンス
└── project.godot          # 最小限のプロジェクト設定
```

## 標準的な反映ワークフロー

### 1. 開発フェーズ（devブランチ）

```bash
# 開発開始
git checkout dev

# 機能開発・修正
# ... コード編集 ...

# テスト実行
../bin/godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# 開発完了
git add .
git commit -m "feat: 新機能実装"
```

### 2. releaseブランチへの反映

#### 2.1 基本的な反映（アドオンのみ）
```bash
# releaseブランチに切り替え
git checkout release

# メインアドオンを反映
git checkout dev -- addons/synclogger/

# コミット
git add addons/synclogger/
git commit -m "feat: [dev反映] メインアドオン更新"
```

#### 2.2 ドキュメント更新が必要な場合
```bash
# README更新が含まれる場合
git checkout dev -- README.md README_ja.md

# 必要に応じて手動調整（release向け最適化）
# 例: devブランチ固有の情報を削除

git add README*.md
git commit -m "docs: README更新"
```

#### 2.3 サンプルレシーバー更新が必要な場合
```bash
# サンプルレシーバー更新
git checkout dev -- sample_receiver.py sample_receiver.bat sample_receiver.sh

git add sample_receiver.*
git commit -m "feat: サンプルレシーバー更新"
```

#### 2.4 包括的な反映（すべて）
```bash
# すべて一度に反映（推奨）
git checkout release
git checkout dev -- addons/synclogger/ README*.md sample_receiver.* LICENSE

# 不要なファイルがあれば削除
rm -f logs.txt test_logs.txt

git add .
git commit -m "feat: [dev反映] v1.x.x 機能統合"
```

### 3. バージョンタグ付け

```bash
# releaseブランチでタグ作成
git tag -a v1.0.0 -m "Release v1.0.0: 初回安定版リリース"

# GitHub等にプッシュ
git push origin release --tags
```

## 注意事項・ベストプラクティス

### ❌ releaseブランチに含めないファイル
- `tests/` - テストスイート
- `docs/` - 開発ドキュメント
- `addons/gut/` - テストフレームワーク
- `demo_logger_integration.*` - デモファイル
- `logs.txt`, `test_logs.txt` - ログファイル
- 一時ファイル類

### ✅ 必須チェック項目
1. **テスト実行**: devブランチで全テスト成功
2. **機能確認**: サンプルレシーバーで動作確認
3. **ドキュメント整合性**: README の機能説明が最新
4. **ファイルサイズ**: release ブランチが軽量（20-30KB程度）
5. **互換性**: Godot 4.4.1+ での動作確認

### 📋 品質チェックリスト

#### 技術チェック
- [ ] 全テスト成功 (60+ tests)
- [ ] gdlint 警告なし
- [ ] サンプルレシーバー動作確認
- [ ] システムログキャプチャ動作確認（Godot 4.5+）

#### ドキュメントチェック
- [ ] README.md（英語版）最新
- [ ] README_ja.md（日本語版）最新
- [ ] API リファレンス正確
- [ ] インストール手順確認

#### リリースチェック
- [ ] 不要ファイル除外
- [ ] sample_receiver.* 動作確認
- [ ] LICENSE ファイル最新
- [ ] バージョン番号整合性

## トラブルシューティング

### 問題: マージ競合が発生
```bash
# 手動で競合解決後
git add <conflicted-files>
git commit -m "fix: マージ競合解決"
```

### 問題: 不要なファイルが混入
```bash
# 特定ファイルをreleaseブランチから削除
git rm <unwanted-file>
git commit -m "chore: 不要ファイル削除"
```

### 問題: devの変更を部分的に取り消したい
```bash
# 特定ファイルの変更を取り消し
git checkout HEAD~1 -- <filename>
git commit -m "revert: <filename> の変更を部分的に取り消し"
```

## 定期メンテナンス

### 月次チェック
- [ ] 依存関係の更新確認
- [ ] Godot新バージョンでの動作確認
- [ ] セキュリティ問題の確認

### リリース前チェック
- [ ] AssetLibrary投稿内容確認
- [ ] GitHub Release ページ準備
- [ ] コミュニティフィードバック反映

---

**📝 履歴**
- 2025-09-21: 初版作成（v1.0.0-beta対応）
- 将来: 必要に応じて手順更新