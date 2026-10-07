defmodule HomepagePhoenixWeb.Layouts do
  @moduledoc """
  このモジュールはアプリケーションで使用される
  レイアウトと関連機能を保持する。
  """
  use HomepagePhoenixWeb, :html

  # layouts/* 内のすべてのファイルをこのモジュールに組み込む。
  # デフォルトの root.html.heex ファイルはアプリケーションの
  # HTML 骨格、つまり HTML ヘッダーなどの静的コンテンツを含む。
  embed_templates "layouts/*"
end
