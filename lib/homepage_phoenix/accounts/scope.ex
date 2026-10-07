defmodule HomepagePhoenix.Accounts.Scope do
  @moduledoc """
  アプリケーション全体で使用される呼び出し元のスコープを定義する。

  `HomepagePhoenix.Accounts.Scope` を使うと、公開インターフェースは呼び出し元の
  情報（エンドユーザーからの呼び出しか、そうであればどのユーザーか）を受け取れる。
  さらにこのスコープは "スーパーユーザー" などの権限フィールドを持ち、認可や
  特定コードパスのスコープ制限に使用できる。

  ログ出力や、呼び出し元がインターフェースを購読する際の PubSub サブスクリプション・
  ブロードキャストのスコープ指定にも有用。

  アプリケーションの要件に合わせて、この構造体のフィールドは自由に拡張できる。
  """

  alias HomepagePhoenix.Accounts.User

  defstruct user: nil

  @doc """
  指定のユーザーのスコープを作成する。

  ユーザーが指定されなければ nil を返す。
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil
end
