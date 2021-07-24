defmodule MemeCacheBot.Model.Meme do
  use Ecto.Schema

  alias MemeCacheBot.Model.{User, Meme}
  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "memes" do
    field(:meme_id, :string)
    field(:meme_unique_id, :string)
    field(:meme_type, :string)
    field(:last_used, :naive_datetime)

    belongs_to(:user, User, references: :telegram_id, type: :integer, foreign_key: :telegram_id)

    timestamps()
  end

  @fields [:meme_id, :meme_unique_id, :meme_type, :last_used]
  @required_fields [:meme_id, :meme_unique_id, :meme_type]
  def insert_changeset(%{} = meme_map) do
    %Meme{}
    |> Changeset.cast(meme_map, @fields)
    |> Changeset.put_assoc(:user, meme_map[:user])
    |> Changeset.validate_required(@required_fields)
  end
end
