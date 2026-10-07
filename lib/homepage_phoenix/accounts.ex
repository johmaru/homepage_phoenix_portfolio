defmodule HomepagePhoenix.Accounts do
  @moduledoc """
  Accounts コンテキスト。
  """

  import Ecto.Query, warn: false
  alias HomepagePhoenix.Repo

  alias HomepagePhoenix.Accounts.{User, UserToken, UserNotifier}

  ## データベース取得

  @doc """
  メールアドレスからユーザーを取得する。

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  メールアドレスとパスワードからユーザーを取得する。

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  単一のユーザーを取得する。

  ユーザーが存在しない場合は `Ecto.NoResultsError` を送出する。

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## ユーザー登録

  @doc """
  ユーザーを登録する。

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.user_registration_changeset(attrs)
    |> Repo.insert()
  end

  ## 設定

  @doc """
  ユーザーのメールアドレス変更用の `%Ecto.Changeset{}` を返す。

  サポートされるオプション一覧は `HomepagePhoenix.Accounts.User.email_changeset/3` を参照。

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  ユーザー名変更用の `%Ecto.Changeset{}` を返す。

  ## Examples

      iex> change_user_username(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_username(user, attrs \\ %{}) do
    User.username_changeset(user, attrs)
  end

  @doc """
  ユーザーのユーザー名を更新する。

  メールアドレス（確認フロー）やパスワード（セッション再書き込み）と異なり、
  単純な DB 更新で済むため LiveView から直接呼べる。
  """
  def update_user_username(user, attrs) do
    user
    |> User.username_changeset(attrs)
    |> Repo.update()
  end

  @spec change_user_registration(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            }
        ) :: Ecto.Changeset.t()
  @doc """
  新規ユーザー登録用の `%Ecto.Changeset{}` を返す。

  ## Options

    * `:validate_unique` - ライブバリデーションでキーストロークごとに
      データベースにアクセスしないよう `false` に設定する。デフォルトは `true`。
  """
  def change_user_registration(user, attrs \\ %{}, opts \\ []) do
    User.user_registration_changeset(user, attrs, opts)
  end

  @doc """
  指定されたトークンでユーザーのメールアドレスを更新する。

  トークンが一致すればユーザーのメールアドレスを更新し、トークンを削除する。
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  ユーザーのパスワード変更用の `%Ecto.Changeset{}` を返す。

  サポートされるオプション一覧は `HomepagePhoenix.Accounts.User.password_changeset/3` を参照。

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  ユーザーのパスワードを更新する。

  更新されたユーザーと、期限切れトークンのリストからなるタプルを返す。

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## セッション

  @doc """
  セッショントークンを生成する。
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  指定の署名付きトークンからユーザーを取得する。

  トークンが有効なら `{user, token_inserted_at}` を返し、無効なら `nil` を返す。
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  指定のマジックリンクトークンからユーザーを取得する。
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  マジックリンクでユーザーをログインさせる。

  以下の 3 つのケースがある:

  1. ユーザーが既にメールアドレスを確認済み。ログインし、
     マジックリンクは期限切れになる。

  2. ユーザーがメールアドレス未確認かつパスワード未設定。
     この場合、ユーザーを確認済みにし、ログインし、セッショントークン含め
     全トークンを期限切れにする。理論上は他にトークンは存在しないが、
     セキュリティのベストプラクティスとしてすべて削除する。

  3. ユーザーがメールアドレス未確認だがパスワードが設定済み。
     デフォルト実装では発生し得ないが、セキュリティ上の落とし穴になり得る。
     `mix help phx.gen.auth` の "Mixing magic link and password registration" 節を参照。
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # 未確認かつパスワード設定済みユーザーのマジックリンクを拒否し、セッション固定攻撃を防止する。
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        パスワード設定済みの未確認ユーザーのマジックリンクログインは許可されていません！

        これはデフォルト実装では発生し得ません。コードを別の用途に改造した可能性が
        あります。`mix help phx.gen.auth` の "Mixing magic link and password
        registration" 節を必ずお読みください。
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  指定のユーザーにメールアドレス更新手順を送信する。

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  指定のユーザーにマジックリンクログイン手順を送信する。
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  指定のコンテキストの署名付きトークンを削除する。
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## トークンヘルパー

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
