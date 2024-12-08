defmodule Decidr.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :name, :string
      add :people_id, references("people")
    end

    alter table(:people) do
      # Foreign key to locations table
      add :locations_id, references("locations", on_delete: :delete_all)
    end

    create table(:people_locations) do
      add :people_id, references("people", on_delete: :nothing)
      add :locations_id, references("locations", on_delete: :nothing)
    end
  end
end
