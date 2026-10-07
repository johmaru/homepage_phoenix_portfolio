defmodule HomepagePhoenixWeb.PageController do
  use HomepagePhoenixWeb, :controller

  def test(conn, _params) do
    conn
    |> render(:test)
  end
end
