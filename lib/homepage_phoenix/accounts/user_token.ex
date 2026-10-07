defmodule HomepagePhoenix.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query
  alias HomepagePhoenix.Accounts.UserToken

  @hash_algorithm :sha256
  @rand_size 32

  # マジックリンクトークンの有効期限は短く保つことが重要。
  # メールへのアクセス権を持つ者がアカウントを乗っ取る可能性があるため。
  @magic_link_validity_in_minutes 15
  @change_email_validity_in_days 7
  @session_validity_in_days 14

  schema "users_tokens" do
    field(:token, :binary)
    field(:context, :string)
    field(:sent_to, :string)
    field(:authenticated_at, :utc_datetime)
    belongs_to(:user, HomepagePhoenix.Accounts.User)

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  セッションや Cookie など、署名付きの場所に保存されるトークンを生成する。
  署名されているため、これらのトークンはハッシュ化不要。

  Phoenix はデフォルトのセッション Cookie を提供するものの、セッショントークンを
  データベースに保存する理由は、Phoenix のデフォルトセッション Cookie は永続化されず、
  単に署名され（場合により暗号化され）ているだけだからである。つまり、署名/暗号化の
  salt を変更しない限り無期限に有効となる。

  そのためデータベースに保存することで、個別のユーザーセッションを期限切れにできる。
  またトークンシステムはログイン時のデバイス情報など追加データを保存できるよう拡張可能。
  この情報を UI で有効な全セッションとデバイスとして表示し、ユーザーが任意の
  セッションを明示的に期限切れにできるようにもできる。
  """
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)
    dt = user.authenticated_at || DateTime.utc_now(:second)
    {token, %UserToken{token: token, context: "session", user_id: user.id, authenticated_at: dt}}
  end

  @doc """
  トークンが有効かどうかを確認し、対応する検索クエリを返す。

  クエリは、トークンから見つかったユーザー（存在する場合）とトークン作成日時を返す。

  トークンはデータベースの値と一致し、かつ有効期限（@session_validity_in_days）を
  過ぎていなければ有効。
  """
  def verify_session_token_query(token) do
    query =
      from(token in by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: {%{user | authenticated_at: token.authenticated_at}, token.inserted_at}
      )

    {:ok, query}
  end

  @doc """
  ユーザーのメールアドレスに配信するトークンとそのハッシュを構築する。

  ハッシュ化されていないトークンはユーザーのメールに送信され、ハッシュ化された
  部分はデータベースに保存される。元のトークンは再構築できないため、データベースに
  読み取り専用でアクセスする者がトークンを直接アプリケーションで使用してアクセスを
  得ることはできない。さらに、ユーザーがシステム内のメールアドレスを変更した場合、
  以前のメールアドレスに送信されたトークンは無効となる。

  ユーザーは既存のコードを容易に改造し、電話番号など他の配信方法を提供できる。
  """
  def build_email_token(user, context) do
    build_hashed_token(user, context, user.email)
  end

  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  トークンが有効かどうかを確認し、対応する検索クエリを返す。

  見つかった場合、クエリは `{user, token}` 形式のタプルを返す。

  指定のトークンは、データベース内のハッシュ値と一致すれば有効。
  この関数はトークンが期限切れかどうかも確認する。マジックリンクトークンの
  コンテキストは常に "login"。
  """
  def verify_magic_link_token_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from(token in by_token_and_context_query(hashed_token, "login"),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^@magic_link_validity_in_minutes, "minute"),
            where: token.sent_to == user.email,
            select: {user, token}
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  トークンが有効かどうかを確認し、対応する検索クエリを返す。

  クエリは、トークンから見つかった user_token（存在する場合）を返す。

  これはユーザーのメールアドレス変更リクエストの検証に使用される。
  指定のトークンは、データベース内のハッシュ値と一致し、かつ有効期限
  （@change_email_validity_in_days）を過ぎていなければ有効。
  コンテキストは常に "change:" で始まる必要がある。
  """
  def verify_change_email_token_query(token, "change:" <> _ = context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from(token in by_token_and_context_query(hashed_token, context),
            where: token.inserted_at > ago(@change_email_validity_in_days, "day")
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  defp by_token_and_context_query(token, context) do
    from(UserToken, where: [token: ^token, context: ^context])
  end
end
