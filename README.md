# Decidr Test App

## Requirements

Ensure compatible versions of [Elixir](https://elixir-lang.org/install.html) and [Phoenix](https://hexdocs.pm/phoenix/installation.html#elixir-1-14-or-later) are installed. 

This app uses the [Ecto](https://hexdocs.pm/ecto/getting-started.html) database wrapper to interact with a PostgreSQL server. Your PostgreSQL database may be setup to:

- not require a username and password. If the above configuration doesn't work, try removing the username and password fields, or setting them both to "postgres", in the [dev.ex](config/dev.exs) file.
- be running on a non-standard port. The default port is 5432. You can specify your specific port by adding it to the config: e.g. port: 15432.

## Installation

Launch the app locally by running the following:
```
git clone git@github.com:FredericCamus/decidr_test.git
cd decidr_test
mix deps.get
mix phx.server
```
Then the app should be accessible from http://localhost:4000. 

To run automated tests, use:
``
mix test
``

To reset the database (drop and re-run migrations), use:
``
MIX_ENV=dev mix ecto.reset
``

## Requirements

PART 1
1. As a user, I should be able to upload this sample CSV and import the data into a
database.
IMPORTER REQUIREMENTS
- [x] The data needs to load into 3 tables. People, Locations and Affiliations
- [x] A Person can belong to many Locations
- [x] A Person can belong to many Affiliations
- [x] A Person without an Affiliation should be skipped
- [x] A Person should have both a first_name and last_name. All fields need to be
validated except for last_name, weapon and vehicle which are optional.
- [x] Names and Locations should all be titlecased

PART 2
- [x] As a user, I should be able to view these results from the importer in a table.
- [x] As a user, I should be able to paginate through the results so that I can see a maximum
of 10 results at a time.
- [x] As a user, I want to type in a search box so that I can filter the results I want to see.
- [x] As a user, I want to be able to click on a table column heading to reorder the visible results.
