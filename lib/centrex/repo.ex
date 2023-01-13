defmodule Centrex.Repo do
  use Ecto.Repo,
    otp_app: :centrex,
    adapter: Ecto.Adapters.Postgres
end
