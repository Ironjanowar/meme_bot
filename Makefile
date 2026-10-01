MIX_ENV ?= dev

.PHONY: deps compile test format check release db_setup db_reset iex

deps:
	mix deps.get

compile: deps
	mix compile --warnings-as-errors

test:
	mix test

format:
	mix format

check:
	MIX_ENV=dev mix deps.get
	MIX_ENV=dev mix format --check-formatted
	MIX_ENV=dev mix compile --warnings-as-errors
	MIX_ENV=dev mix credo --strict --min-priority high
	MIX_ENV=test mix test
	MIX_ENV=dev mix hex.audit

release:
	MIX_ENV=prod mix deps.get --only prod
	MIX_ENV=prod mix compile --warnings-as-errors
	MIX_ENV=prod mix release --overwrite

db_setup:
	mix ecto.create
	mix ecto.migrate

db_reset:
	mix ecto.drop
	mix ecto.create
	mix ecto.migrate

iex:
	iex -S mix
