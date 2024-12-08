defmodule DecidrWeb.UploadsLive do
  use DecidrWeb, :live_view
  alias NimbleCSV.RFC4180, as: CSV
  alias Decidr.People
  alias Decidr.Locations
  alias Decidr.Affiliations
  alias Decidr.Repo
  require Logger
  import Ecto.Query, only: [from: 2, subquery: 1]

  # Named file will be saved as
  @file_path Path.join(Application.app_dir(:decidr, "priv/static/uploads"), "user_file")
  @limit 10
  @offset 0
  @order {true, :id} # Indicates {ascending, feature to order by}
  @serach_query "%%"

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:limit, @limit)
      |> assign(:offset, @offset)
      |> assign(:order, @order)
      |> assign(:search_query, "%%")
      |> assign(:form, Phoenix.HTML.Form.input_name(:user, :search_query))
      |> assign(:people, get_people())
      |> assign(:locations, get_locations())
      |> assign(:affiliations, get_affiliations())
      |> assign(:uploaded_files, [])
      |> allow_upload(:user_file, accept: ~w(.csv), max_entries: 1)
    }
  end

  defp get_people(limit \\ @limit, offset \\ @offset, order \\ @order, search_query \\ @serach_query) do
    # Create subqueries for searching associations
    sub_query_a = from(a in Affiliations, select: a.id, where: ilike(a.name, ^search_query))
    sub_query_l = from(l in Locations, select: l.id, where: ilike(l.name, ^search_query))

    # Query based on order case
    query = case order do
      {true, o} -> from(u in People,
            select: u,
            group_by: u.id,
            order_by: [asc: ^o],
            limit: ^limit,
            offset: ^offset,
            join: a in assoc(u, :affiliations),
            join: l in assoc(u, :locations),
            where: a.id in subquery(sub_query_a) or
                  l.id in subquery(sub_query_l) or
                  ilike(u.first_name, ^search_query) or
                  ilike(u.last_name, ^search_query) or
                  ilike(u.species, ^search_query) or
                  ilike(u.gender, ^search_query) or
                  ilike(u.vehicle, ^search_query) or
                  ilike(u.weapon, ^search_query))
      {false, o} -> from(u in People,
            select: u,
            group_by: u.id,
            order_by: [desc: ^o],
            limit: ^limit,
            offset: ^offset,
            join: a in assoc(u, :affiliations),
            join: l in assoc(u, :locations),
            where: a.id in subquery(sub_query_a) or
                  l.id in subquery(sub_query_l) or
                  ilike(u.first_name, ^search_query) or
                  ilike(u.last_name, ^search_query) or
                  ilike(u.species, ^search_query) or
                  ilike(u.gender, ^search_query) or
                  ilike(u.vehicle, ^search_query) or
                  ilike(u.weapon, ^search_query))
    end

    # Return all People structs matching the query and load them into the liveview
    Repo.all(query)
    |> Enum.map(& Repo.preload(&1, :locations))
    |> Enum.map(& Repo.preload(&1, :affiliations))
  end

  # Get all location structs matching some conditions
  defp get_locations(limit \\ 100, offset \\ 0) do
    query = from(u in Locations, select: u, limit: ^limit, offset: ^offset)
    Repo.all(query)
    |> Enum.map(& Repo.preload(&1, :people))
  end

  # Get all affiliation structs matching some conditions
  defp get_affiliations(limit \\ 100, offset \\ 0) do
    query = from(u in Affiliations, select: u, limit: ^limit, offset: ^offset)
    Repo.all(query)
    |> Enum.map(& Repo.preload(&1, :people))
  end

  @impl Phoenix.LiveView
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  # Upload files to the /priv/static/uploads/ directory
  @impl Phoenix.LiveView
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :user_file, fn %{path: path}, _entry ->
        dest = @file_path
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)
    {:noreply,
      socket
      |> update(:uploaded_files, &(&1 ++ uploaded_files))
      |> process_file()
    }
  end

  # Returns results given teh search query
  @impl Phoenix.LiveView
  def handle_event("update_search", %{"search" => search}, socket) do
    search_query = "%" <> search <> "%"
    {:noreply,
      socket
      |> assign(:search_query, search_query)
      |> assign(:people, get_people(socket.assigns.limit, socket.assigns.offset, socket.assigns.order, search_query))
    }
  end

  @impl Phoenix.LiveView
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :user_file, ref)}
  end

  @impl Phoenix.LiveView
  def handle_event("order_people", %{"id" => id}, socket) do
    new_order_feature = String.to_atom(id)
    {old_asc_bool, old_order} = socket.assigns.order
    # If the order feature is the same, reverse the order
    order = case old_order == new_order_feature do
      true -> {!old_asc_bool, new_order_feature}
      false -> {old_asc_bool, new_order_feature}
    end
    {:noreply,
      socket
      |> assign(order: order)
      |> assign(:people, get_people(socket.assigns.limit, socket.assigns.offset, order))
    }
  end

  # Paginate by increasing offset if within records domain
  def handle_event("paginate", %{"offset" => offset_string}, socket) do
    offset = String.to_integer(offset_string)
    num_people = Repo.all(from p in People, select: p.first_name) |> Enum.count
    case offset < num_people do
      false -> {:noreply, socket}
      true ->
        new_offset = max(0, offset)
        {:noreply,
          socket
          |> assign(offset: new_offset)
          |> assign(:people, get_people(socket.assigns.limit, new_offset, socket.assigns.order))
        }
    end
  end

  def get_class("nav_button"), do: "bg-gray-500 hover:bg-gray-700 text-white font-bold py-1 px-2 rounded"

  # Stream the file into the database
  defp process_file(socket) do
    @file_path
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.each(fn line ->
      case process_line(line) do
        {:ok, _} ->
          Logger.info("Inserted line: #{IO.inspect(line)}")
        {:error, message} ->
          Logger.warning("Failed to process line. Got error: #{message}")
      end
    end)
    |> Stream.run()

    # Return updated socket
    socket
    |> assign(:people, get_people(socket.assigns.limit, socket.assigns.offset))
    |> assign(:locations, get_locations())
    |> assign(:affiliations, get_affiliations())
  end

  # Clean teh data based on the given conditions
  defp process_line([
          name,
          location,
          species,
          gender,
          affiliation,
          weapon,
          vehicle
        ]) do
    with {:ok, {first_name, last_name}} <- process_name(name),
          {:ok, locations} <- process_location(location),
          {:ok, processed_gender} <- process_gender(gender),
          {:ok, affiliations} <- process_affiliations(affiliation),
          {:ok} <- unique_person(first_name, last_name) do

      # If an affiliation or location already exists, use that, otherwise create new struct
      locations_struct = find_locations(locations)
      affiliations_struct = find_affiliations(affiliations)

      changeset = People.changeset(%People{}, %{
        first_name: first_name,
        last_name: last_name,
        locations: locations_struct,
        species: species,
        gender: processed_gender,
        affiliations: affiliations_struct,
        weapon: weapon,
        vehicle: vehicle
      })

      Repo.insert(changeset)
    else
      {:error, message} -> {:error, message}
      _ -> {:error, "Unkown error!"}
    end
  end

  def unique_person(first_name, last_name) do
    case Repo.get_by(People, first_name: first_name, last_name: last_name) do
      nil -> {:ok}
      _ -> {:error, "Person already exists! #{first_name}"}
    end
  end

  def find_locations(locations) do
    Enum.map(locations, fn loc ->
      case Repo.get_by(Locations, name: loc) do
        nil -> %Locations{name: loc}
        struct -> struct
      end
    end)
  end

  def find_affiliations(affiliations) do
    Enum.map(affiliations, fn aff ->
      case Repo.get_by(Affiliations, name: aff) do
        nil -> %Affiliations{name: aff}
        struct -> struct
      end
    end)
  end

  def optional_attribute(attribute) do
    case attribute do
      "" -> "unkown"
      nil -> "unkown"
      x -> x
    end
  end

  defp process_name(name) do
    case String.split(name, " ", trim: true) do
      [head] ->
        {:ok, {:string.titlecase(head), "unkown"}}
      [head | tail] ->
        {:ok, {:string.titlecase(head), Enum.join(tail, " ") |> :string.titlecase}}
      _ ->
        {:error, "Failed to process name: #{name}"}
    end
  end

  defp process_location(location) do
    {:ok, String.split(location, ", ", trim: true) |> Enum.map(& :string.titlecase(&1))}
  end

  defp process_affiliations(affiliations) do
    case String.split(affiliations, ", ", trim: true) do
      [] -> {:error, "No affiliations."}
      a -> {:ok, a}
    end
  end

  defp process_gender(gender) do
    map = %{
      "male" => "male",
      "m" => "male",
      "female" => "female",
      "f" => "female"
    }
    case map[String.downcase(gender)] do
      nil -> {:ok, "other"}
      x -> {:ok, x}
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
