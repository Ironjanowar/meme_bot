defmodule MemeCacheBot.Repo.Migrations.CreateMemeTags do
  use Ecto.Migration

  def change do
    create table(:meme_tags, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :meme_id,
        references(:memes, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:tag, :string, null: false)
      timestamps()
    end

    create(unique_index(:meme_tags, [:meme_id, :tag]))
    create(index(:meme_tags, [:tag]))
    create(index(:meme_tags, [:meme_id]))
  end
end
