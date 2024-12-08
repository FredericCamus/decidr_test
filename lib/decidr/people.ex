defmodule Decidr.People do
  use Ecto.Schema
  import Ecto.Changeset
  alias Decidr.Locations
  alias Decidr.Affiliations


  schema "people" do
    field :first_name, :string
    field :last_name, :string
    many_to_many :locations, Locations, join_through: "people_locations"
    field :species, :string
    field :gender, :string
    many_to_many :affiliations, Affiliations, join_through: "people_affiliations"
    field :weapon, :string
    field :vehicle, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:first_name, :last_name, :species, :gender, :vehicle, :weapon])
    |> put_assoc(:affiliations, attrs.affiliations)
    |> put_assoc(:locations, attrs.locations)
    |> validate_required([:first_name, :locations, :species, :gender, :affiliations])
  end
end
