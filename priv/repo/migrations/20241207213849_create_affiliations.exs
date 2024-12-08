defmodule Decidr.Repo.Migrations.CreateAffiliations do
  use Ecto.Migration

  def change do
    create table(:affiliations) do
      add :name, :string
      add :people_id, references("people")
    end

    alter table(:people) do
      # Foreign key to locations table
      add :affiliations_id, references("affiliations", on_delete: :delete_all)
    end

    create table(:people_affiliations) do
      add :people_id, references("people", on_delete: :nothing)
      add :affiliations_id, references("affiliations", on_delete: :nothing)
    end
  end
end
