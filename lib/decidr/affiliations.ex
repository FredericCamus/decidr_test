defmodule Decidr.Affiliations do
  use Ecto.Schema
  alias Decidr.People
  import Ecto.Changeset

  schema "affiliations" do
    field :name, :string
    many_to_many :people, People, join_through: "people_affiliations"
  end

  def changeset(data, attrs) do
    data
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
