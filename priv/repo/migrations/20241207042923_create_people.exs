defmodule Decidr.Repo.Migrations.CreatePeople do
  use Ecto.Migration

  def change do
    create table(:people) do
      add :first_name, :string
      add :last_name, :string
      add :species, :string
      add :gender, :string
      add :weapon, :string
      add :vehicle, :string

      timestamps(type: :utc_datetime)
    end
  end
end
