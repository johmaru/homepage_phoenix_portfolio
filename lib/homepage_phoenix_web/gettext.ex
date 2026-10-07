defmodule HomepagePhoenixWeb.Gettext do
  @moduledoc """
  gettext ベースの API で国際化を提供するモジュール。

  [Gettext](https://hexdocs.pm/gettext) を使用すると、モジュールが翻訳をコンパイルし、
  アプリケーションで利用できるようになる。この Gettext バックエンドモジュールを
  使用するには、`use Gettext` を呼び出してオプションとして渡す:

      use Gettext, backend: HomepagePhoenixWeb.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

  詳しい使い方は [Gettext Docs](https://hexdocs.pm/gettext) を参照。
  """
  use Gettext.Backend, otp_app: :homepage_phoenix
end
