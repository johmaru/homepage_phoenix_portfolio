defmodule HomepagePhoenixWeb.PageHTML do
  @moduledoc """
  このモジュールには PageController がレンダリングするページが含まれる。

  利用可能なすべてのテンプレートは `page_html` ディレクトリを参照。
  """
  use HomepagePhoenixWeb, :html

  embed_templates "page_html/*"
end
