defmodule HomepagePhoenix.AccountsFixtures do
  @moduledoc """
  このモジュールは `HomepagePhoenix.Accounts` コンテキスト経由で
  エンティティを作成するテストヘルパーを定義する。
  """

  import Ecto.Query

  alias HomepagePhoenix.Accounts
  alias HomepagePhoenix.Accounts.User
  alias HomepagePhoenix.Accounts.Scope

  # ランダム値ベースで生成する。System.unique_integer のカウンターは
  # VM 起動ごとにリセットされるため、テスト DB に残留データがあると
  # 後続のテストランで一意制約違反（email/username の重複）が起きる。
  def unique_user_email,
    do: "user_#{Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)}@example.com"

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: "user_#{Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)}",
      password: valid_user_password(),
      password_confirmation: valid_user_password()
    })
  end

  @doc """
  パスワードなしでユーザーを登録するための属性を返す。

  ユーザーを登録した後マジックリンクでログインするフィクスチャで使用。
  `login_user_by_magic_link/1` はパスワード設定済みの未確認ユーザーを
  拒否するため。
  """
  def valid_user_attributes_without_password(attrs \\ %{}) do
    valid_user_attributes(attrs)
    |> Map.drop([:password, :password_confirmation])
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    # valid_user_attributes/1 が :password を含むようになったため、
    # ユーザーはパスワード設定済みの未確認状態となる。
    # login_user_by_magic_link/1 はこの組み合わせを拒否するため
    # （セッション固定攻撃対策）、先にアカウントを確認済みにして
    # からマジックリンクでログインする。
    user = HomepagePhoenix.Repo.update!(User.confirm_changeset(user))

    token =
      extract_user_token(fn url ->
        Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} = Accounts.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def admin_user_fixture(attrs \\ %{}) do
    attrs = Map.put(attrs, :is_admin, true)
    user = user_fixture(attrs)

    # user_fixture が is_admin を上書きする可能性があるため、
    # ここで明示的に is_admin: true を設定し直す。
    HomepagePhoenix.Repo.update!(Ecto.Changeset.change(user, is_admin: true))
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Accounts.UserToken.build_email_token(user, "login")
    HomepagePhoenix.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    HomepagePhoenix.Repo.update_all(
      from(ut in Accounts.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end
end
