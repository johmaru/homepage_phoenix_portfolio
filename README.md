# homepage_phoenix_portfolio

Elixir / Phoenix の学習を目的に開発し、現在も個人サイトとして継続的に改善している Web アプリケーションです。

ユーザー認証、ブログ、管理画面、メモ機能などを実装し、Phoenix LiveView や Ecto、PostgreSQL を使った Web アプリケーション開発を学んでいます。

## 主な技術

- Elixir
- Phoenix 1.8
- Phoenix LiveView
- Ecto
- PostgreSQL
- HEEx
- ExUnit / Phoenix.LiveViewTest
- Tailwind CSS
- Docker

## 主な機能

- ユーザー登録・ログイン・セッション認証
- ユーザー設定
- 管理者権限と管理画面
- ブログ投稿の作成・編集・削除・公開
- Draft / Published と公開日時による表示制御
- タグ付け・タグ別絞り込み
- ページング
- Markdown から HTML への変換
- 見出しからの目次生成
- 画像ストレージの抽象化
- 活動履歴
- メモ作成・共有
- sitemap.xml 生成
- Context / LiveView / Controller のテスト

## 構成

```text
lib/
  homepage_phoenix/       # Context、Ecto、ドメインロジック
  homepage_phoenix_web/   # LiveView、Controller、Router、UI
priv/
  repo/migrations/        # DB migration
test/                     # Context / LiveView / Controller のテスト
config/                   # Phoenix 設定
```

サーバーサイドでは Context と Ecto を用いて、DB アクセスや認証、ブログ・タグ・メモなどの処理を Web 層から分離しています。

## コードを見る場合

- `lib/homepage_phoenix/accounts.ex`  
  ユーザー登録、認証、セッションなどの Accounts Context
- `lib/homepage_phoenix/blog.ex`  
  投稿、公開状態、ページング、タグなどの Blog Context
- `lib/homepage_phoenix/blog/renderer.ex`  
  Markdown レンダリングと目次生成
- `lib/homepage_phoenix_web/router.ex`  
  通常ページ、認証、管理者向けルート
- `lib/homepage_phoenix_web/user_auth.ex`  
  セッション認証と LiveView の on_mount
- `lib/homepage_phoenix_web/live/admin/post_form_live.ex`  
  管理画面の投稿作成・編集
- `priv/repo/migrations/`  
  PostgreSQL のスキーマ変更
- `test/`  
  Context、認証、LiveView などのテスト

## 学習目的

既存の個人サイトを Phoenix で作り直しながら、Elixir / Phoenix を実践的に学ぶ目的で始めました。

チュートリアルだけで終わらせず、継続して使うサイトとして認証、DB、管理機能、テストなどを実装しながら改善しています。
