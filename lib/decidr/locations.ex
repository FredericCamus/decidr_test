defmodule Decidr.Locations do
  use Ecto.Schema
  alias Decidr.People
  import Ecto.Changeset

  schema "locations" do
    field :name, :string
    many_to_many :people, People, join_through: "people_locations"
  end

  def changeset(data, attrs) do
    data
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
