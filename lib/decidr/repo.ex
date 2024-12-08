defmodule Decidr.Repo do
  use Ecto.Repo,
    otp_app: :decidr,
    adapter: Ecto.Adapters.Postgres
end
