defmodule HomepagePhoenixWeb.ConnCase do
  @moduledoc """
  このモジュールはコネクションのセットアップが必要な
  テストで使用されるテストケースを定義する。
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # テスト用のデフォルトエンドポイント
      @endpoint HomepagePhoenixWeb.Endpoint

      use HomepagePhoenixWeb, :verified_routes

      # コネクションテストの便利関数を import
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import HomepagePhoenixWeb.ConnCase
    end
  end

  setup tags do
    HomepagePhoenix.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  ユーザーを登録してログインするセットアップヘルパー。

      setup :register_and_log_in_user

  更新されたコネクションと登録済みユーザーを
  テストコンテキストに格納する。
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = HomepagePhoenix.AccountsFixtures.user_fixture()
    scope = HomepagePhoenix.Accounts.Scope.for_user(user)

    %{conn: log_in_user(conn, user), user: user, scope: scope}
  end

  @doc """
  管理者ユーザーを登録してログインするセットアップヘルパー。
  """
  def register_and_log_in_admin_user(%{conn: conn}) do
    user = HomepagePhoenix.AccountsFixtures.admin_user_fixture()
    scope = HomepagePhoenix.Accounts.Scope.for_user(user)

    %{conn: log_in_user(conn, user), user: user, scope: scope}
  end

  @doc """
  指定の `user` を `conn` にログインさせる。

  更新された `conn` を返す。
  """
  def log_in_user(conn, user) do
    token = HomepagePhoenix.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
