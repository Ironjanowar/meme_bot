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
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    %Meme{}
    |> Changeset.cast(meme_map, @fields)
    |> Changeset.put_change(:last_used, now)
    |> Changeset.put_assoc(:user, meme_map[:user])
    |> Changeset.validate_required(@required_fields)
    |> Changeset.unique_constraint([:meme_unique_id, :telegram_id], name: :meme_user_unique_index)
  end

  @updatable_fields [:last_used]
  def update_changeset(%Meme{} = meme, params) do
    Changeset.cast(meme, params, @updatable_fields)
  end

  def build(%{} = meme_map) do
    meme_map
    |> insert_changeset()
    |> Changeset.apply_action(:insert)
    |> elem(1)
  end
end
