defmodule MemeCacheBot.Model.User do
  use Ecto.Schema

  alias MemeCacheBot.Model.Meme

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:telegram_id, :integer)
    field(:first_name, :string)
    field(:username, :string)

    has_many(:memes, Meme)

    timestamps()
  end
end
