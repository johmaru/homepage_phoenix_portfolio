defmodule HomepagePhoenix.Repo do
  use Ecto.Repo,
    otp_app: :homepage_phoenix,
    adapter: Ecto.Adapters.Postgres
end
