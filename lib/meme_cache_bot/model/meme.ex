defmodule MemeCacheBot.Model.Meme do
  use Ecto.Schema

  alias MemeCacheBot.Model.User

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "memes" do
    field(:meme_id, :string)
    field(:meme_unique_id, :string)
    field(:meme_type, :string)
    field(:last_used, :naive_datetime)

    belongs_to(:user, User, references: :telegram_id, type: :integer)

    timestamps()
  end
end
