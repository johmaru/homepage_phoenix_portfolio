# homepage_phoenix_portfolio

Elixir / Phoenix の学習を目的に開発し、現在も個人サイトとして継続的に改善している Web アプリケーションの公開ポートフォリオ版です。

この Public リポジトリは、実運用している Private リポジトリから採用・コードレビュー向けの部分を抜き出した **sanitized snapshot** です。機密情報、インフラ固有値、権利上公開に適さない画像・メディア、開発用エージェント指示、元の Git 履歴は含めていません。

## 主な技術

- Elixir
- Phoenix 1.8
- Phoenix LiveView
- Ecto
- PostgreSQL
- HEEx
- ExUnit / Phoenix.LiveViewTest
- Tailwind CSS（実運用版）
- Docker（実運用版の開発環境）

## 実装している主な機能

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
- Phoenix LiveView を利用した画面更新
- sitemap.xml 生成
- Context / LiveView / Controller のテスト

## コードを見る場合

特に以下のファイル・ディレクトリで、サーバーサイドの実装を確認できます。

- `lib/homepage_phoenix/accounts.ex`  
  ユーザー登録、認証、セッション、メール変更などの Accounts Context
- `lib/homepage_phoenix/blog.ex`  
  投稿、公開状態、ページング、タグなどの Blog Context
- `lib/homepage_phoenix/blog/renderer.ex`  
  Markdown レンダリングと目次生成
- `lib/homepage_phoenix_web/router.ex`  
  通常ページ、認証、管理者向けルートの構成
- `lib/homepage_phoenix_web/user_auth.ex`  
  セッション認証と LiveView の on_mount
- `lib/homepage_phoenix_web/live/admin/post_form_live.ex`  
  管理画面の投稿作成・編集
- `priv/repo/migrations/`  
  PostgreSQL のスキーマ変更
- `test/`  
  Context、認証、LiveView 等のテスト

## 設計

```text
lib/
  homepage_phoenix/       # Context、Ecto、ドメインロジック
  homepage_phoenix_web/   # LiveView、Controller、Router、UI
priv/
  repo/migrations/        # DB migration
test/                     # Context / LiveView / Controller のテスト
config/                   # Phoenix 設定（公開用にサニタイズ済み）
```

サーバーサイドでは Context と Ecto を用いて、DB アクセスや認証、ブログ・タグ・メモ等の処理を Web 層から分離しています。Web 層では Phoenix LiveView と Router を利用しています。

## 学習目的

既存の個人サイトを Phoenix で作り直しながら、Elixir / Phoenix を実践的に学ぶ目的で始めました。

単純なチュートリアルではなく、実際に継続運用するサイトとして、認証、DB、管理機能、テスト、デプロイを含めて改善しています。

## AI 支援について

開発では AI コーディング支援も利用しています。仕様の調整、生成コードの確認、デバッグ、テスト、動作検証を行いながら開発・保守しています。

## この公開版に含めていないもの

- 本番環境の Secret / Credential
- Cloud / OCI 固有の識別情報
- 本番デプロイ用スクリプト
- 実サイトで利用している画像・メディア
- UI の一部 assets
- 元の Private リポジトリの Git 履歴

そのため、このリポジトリは本番サイトの完全な配布物ではなく、**実装内容を確認するためのコードレビュー用ポートフォリオ**として公開しています。