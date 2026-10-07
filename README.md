# homepage_phoenix_portfolio

Elixir / Phoenix の学習を目的に開発し、現在も個人サイトとして継続的に改善している Web アプリケーションの公開ポートフォリオ版です。

このリポジトリは採用・ポートフォリオ閲覧向けに、実運用リポジトリから機密情報、インフラ固有値、権利上公開に適さない画像、開発用エージェント指示などを除いて構成しています。元の Git 履歴も引き継いでいません。

## 主な技術

- Elixir
- Phoenix 1.8
- Phoenix LiveView
- Ecto
- PostgreSQL
- HEEx
- Tailwind CSS
- Docker
- ExUnit

## 実装している主な機能

- ユーザー登録・ログイン・セッション認証
- ユーザー設定
- 管理者権限による管理画面
- ブログ投稿の作成・編集・削除・公開
- Draft / Published と公開日時による表示制御
- タグ付け・タグ別絞り込み
- ページング
- Markdown から HTML への変換
- 見出しからの目次生成
- 画像ストレージの抽象化
- 活動履歴・メモ機能
- Phoenix LiveView を利用したインタラクティブ UI
- sitemap.xml 生成
- ExUnit / Phoenix.LiveViewTest によるテスト

## 構成

```text
lib/
  homepage_phoenix/       # Context、Ecto、ドメインロジック
  homepage_phoenix_web/   # LiveView、Controller、Router、UI
priv/
  repo/migrations/        # DB migration
test/                     # Context / LiveView / Controller のテスト
assets/                   # CSS / JavaScript
config/                   # Phoenix 設定
```

特にサーバーサイドでは、Context と Ecto を用いて DB アクセスや認証、ブログ・タグ・メモ等の処理を分離し、Web 層では LiveView と Router を利用しています。

## 学習目的について

このプロジェクトは、既存の個人サイトを Phoenix で作り直しながら Elixir / Phoenix を実践的に学ぶ目的で始めました。単純なチュートリアルではなく、実際に継続運用するサイトとして、認証、DB、管理機能、テスト、デプロイを含めて改善しています。

## AI 支援について

開発では AI コーディング支援も利用しています。仕様の調整、生成コードの確認、デバッグ、テスト、動作検証を行いながら開発・保守しています。

## ローカル起動

Docker を利用する場合:

```bash
docker compose up -d --build
docker compose exec app mix ecto.setup
```

その後、`http://localhost:4000` を開きます。

テスト:

```bash
docker compose exec -e MIX_ENV=test app mix test
```

## 公開版について

このポートフォリオ版には以下を含めていません。

- 本番環境の Secret / Credential
- Cloud / OCI 固有の識別情報
- 本番デプロイ用スクリプト
- 実サイトで利用している一部の画像・メディア
- 元の Private リポジトリの Git 履歴

設定値は環境変数から与える前提です。
