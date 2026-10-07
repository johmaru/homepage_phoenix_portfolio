# データベースにデータを投入するスクリプト。
#
# 次のように実行できる:
#
#     mix run priv/repo/seeds.exs
#
# スクリプト内では、任意のリポジトリに直接読み書きできる:
#
#     HomepagePhoenix.Repo.insert!(%HomepagePhoenix.SomeSchema{})
#
# 問題発生時に確実に失敗させるため、バング関数（`insert!`, `update!`
# 等）の使用を推奨。

alias HomepagePhoenix.{Repo, Accounts.User}

# Johmaru 管理者アカウント。
# 本番では環境変数 ADMIN_EMAIL / ADMIN_USERNAME / ADMIN_PASSWORD が必須。
admin_email = System.get_env("ADMIN_EMAIL") || "admin@example.com"
admin_username = System.get_env("ADMIN_USERNAME") || "portfolio-admin"

admin_password =
  System.get_env("ADMIN_PASSWORD") ||
    if System.get_env("PHX_SERVER") do
      raise "ADMIN_PASSWORD environment variable is required in production"
    else
      "change_me_in_production"
    end

case Repo.get_by(User, email: admin_email) do
  nil ->
    %User{}
    |> User.user_registration_changeset(%{
      "email" => admin_email,
      "username" => admin_username,
      "password" => admin_password
    })
    |> User.confirm_changeset()
    |> Ecto.Changeset.change(%{is_admin: true})
    |> Repo.insert!()

  user ->
    user
    |> Ecto.Changeset.change(%{is_admin: true})
    |> Repo.update!()
end
