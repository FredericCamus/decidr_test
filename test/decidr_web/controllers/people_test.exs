defmodule Decidr.PeopleTest do
  alias Decidr.Repo
  alias Decidr.People
  alias Decidr.Locations

  import Ecto.Query, only: [from: 2]

  use Decidr.RepoCase

  test "schema matches database" do
    person = Repo.insert!(%People{first_name: "Bob", last_name: "Hawking"})
    assert person.first_name == "Bob"
    assert person.last_name == "Hawking"
  end

  test "single people-location relation" do
    location = Repo.insert!(%Locations{name: "Metropolis"})
    people = Repo.insert!(%People{first_name: "Bob", last_name: "Hawking", locations: [location]})

    test_location = Repo.get!(Locations, location.id) |> Repo.preload(:people)
    test_people = Repo.get!(People, people.id) |> Repo.preload(:locations)

    assert test_location.people |> Enum.at(0) |> Map.get(:first_name) == "Bob"
    assert test_location.people |> Enum.at(0) |> Map.get(:last_name) == "Hawking"
    assert test_people.locations |> Enum.at(0) |> Map.get(:name) == "Metropolis"
  end

  test "multiple people-location relation" do
    location1 = Repo.insert!(%Locations{name: "Metropolis"})
    location2 = Repo.insert!(%Locations{name: "Ionia"})
    person1 = Repo.insert!(%People{first_name: "Bob", last_name: "Hawking", locations: [location1, location2]})
    person2 = Repo.insert!(%People{first_name: "Belisarius", locations: [location1, location2]})

    test_location1 = Repo.get!(Locations, location1.id) |> Repo.preload(:people)
    test_location2 = Repo.get!(Locations, location2.id) |> Repo.preload(:people)
    test_person1 = Repo.get!(People, person1.id) |> Repo.preload(:locations)
    test_person2 = Repo.get!(People, person2.id) |> Repo.preload(:locations)

    query = from u in People, select: u
    Repo.all(query)
    |> Enum.map(& Repo.preload(&1, :locations))
    |> Enum.map(& Repo.preload(&1, :affiliations))
    |> dbg

    assert test_location1.people |> Enum.at(0) |> Map.get(:first_name) == "Bob"
    assert test_location2.people |> Enum.at(1) |> Map.get(:first_name) == "Belisarius"

    assert test_person1.locations |> Enum.at(0) |> Map.get(:name) == "Metropolis"
    assert test_person2.locations |> Enum.at(1) |> Map.get(:name) == "Ionia"
  end

end
