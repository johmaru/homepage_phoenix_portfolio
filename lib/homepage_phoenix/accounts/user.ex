defmodule HomepagePhoenix.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:username, :string, default: "")
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:confirmed_at, :utc_datetime)
    field(:authenticated_at, :utc_datetime, virtual: true)
    field(:is_admin, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  @doc """
  ユーザー登録時またはメールアドレス変更用の changeset。

  メールアドレスの変更がない場合はエラーが追加される。

  ## Options

    * `:validate_unique` - メールアドレスの一意性を検証したくない場合は
      `false` に設定する。ライブバリデーション表示時に有用。
      デフォルトは `true`。
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  ユーザー名変更用の changeset。

  メールアドレスやパスワードと異なり確認フローやセッション書き換えが
  不要なため、LiveView から直接更新できるシンプルな構成。
  """
  def username_changeset(user, attrs) do
    user
    |> cast(attrs, [:username])
    |> validate_username()
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, HomepagePhoenix.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  @doc """
  パスワード変更用の changeset。

  長いパスワードは特定のアルゴリズムでハッシュ計算が非常に高コストに
  なるため、パスワード長の検証が重要。

  ## Options

    * `:hash_password` - パスワードをハッシュしてデータベースに安全に
      格納し、ログ漏洩を防ぐため password フィールドを消去する。
      パスワードのハッシュが不要でフィールド消去も望まない場合
      （LiveView フォームのバリデーション等）は `false` に設定可能。
      デフォルトは `true`。
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # 追加のパスワードバリデーションの例:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Bcrypt を使用する場合、最大 72 バイトまで検証する。
      |> validate_length(:password, max: 72, count: :bytes)
      # ハッシュは `Ecto.Changeset.prepare_changes/2` でも行えるが、
      # そうするとデータベーストランザクションの時間が長くなり性能に影響する。
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  ユーザー登録用の changeset。

  メールアドレス、ユーザー名、パスワードを一緒に検証するため、
  全フィールドを一度に入力する登録フォームに適している。

  ## Options

    * `:validate_unique` - ライブバリデーションでキーストロークごとに
      データベースにアクセスしないよう `false` に設定する。デフォルトは `true`。
    * `:hash_password` - ハッシュをスキップする場合 `false` に設定（ライブバリデーション
      で有用）。デフォルトは `true`。
  """
  def user_registration_changeset(user, attrs, opts \\ []) do
    changeset =
      user
      |> cast(attrs, [:email, :username, :password])
      |> validate_email(opts)
      |> validate_username()
      |> validate_confirmation(:password, message: "does not match password")

    # パスワードが入力されている場合のみ検証・ハッシュする。
    # これによりパスワード不要のマジックリンク登録を可能にする。
    if get_field(changeset, :password) do
      changeset |> validate_password(opts)
    else
      changeset
    end
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, and underscores"
    )
  end

  @doc """
  `confirmed_at` を設定してアカウントを確認済みにする。
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  パスワードを検証する。

  ユーザーが存在しない、またはパスワード未設定の場合は
  タイミング攻撃を防ぐため `Bcrypt.no_user_verify/0` を呼び出す。
  """
  def valid_password?(%HomepagePhoenix.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
