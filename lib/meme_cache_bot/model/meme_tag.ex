defmodule MemeCacheBot.Model.MemeTag do
  use Ecto.Schema

  alias Ecto.Changeset
  alias MemeCacheBot.Model.{Meme, MemeTag}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "meme_tags" do
    field(:tag, :string)
    belongs_to(:meme, Meme, type: :binary_id)
    timestamps()
  end

  def changeset(%MemeTag{} = meme_tag, params) do
    meme_tag
    |> Changeset.cast(params, [:meme_id, :tag])
    |> Changeset.validate_required([:meme_id, :tag])
    |> Changeset.unique_constraint([:meme_id, :tag])
  end
end
