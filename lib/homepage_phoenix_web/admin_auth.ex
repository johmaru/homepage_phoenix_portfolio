defmodule HomepagePhoenixWeb.AdminAuth do
  use HomepagePhoenixWeb, :verified_routes

  @moduledoc """
  管理者権限を要求する LiveView on_mount コールバック。

  `mount_current_scope` → `require_authenticated_user` の後に実行する前提。
  on_mount の並び順が変わってもクラッシュしないよう、defensive にアクセスする
  （`user_auth.ex` の既存パターンに合わせる）。
  """
  import Phoenix.LiveView, only: [push_navigate: 2]

  def on_mount(:require_admin, _params, _session, socket) do
    user =
      case socket.assigns[:current_scope] do
        %{user: %{is_admin: true} = u} -> u
        _ -> nil
      end

    if user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, "アクセス権限がありません")
        |> push_navigate(to: ~p"/")

      {:halt, socket}
    end
  end
end
