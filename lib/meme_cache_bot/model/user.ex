defmodule MemeCacheBot.Model.User do
  use Ecto.Schema

  alias MemeCacheBot.Model.{User, Meme}
  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field(:telegram_id, :integer)
    field(:first_name, :string)
    field(:username, :string)

    has_many(:memes, Meme, references: :telegram_id, foreign_key: :telegram_id)

    timestamps()
  end

  @fields [:telegram_id, :first_name, :username]
  @required_fields [:telegram_id]
  def insert_changeset(%{} = user_map) do
    %User{}
    |> Changeset.cast(user_map, @fields)
    |> Changeset.validate_required(@required_fields)
  end
end
