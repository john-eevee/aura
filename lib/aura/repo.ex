defmodule Aura.Repo do
  use Ecto.Repo,
    otp_app: :aura,
    adapter: Ecto.Adapters.Postgres
end
