defmodule MemeCacheBot.Repo.Migrations.CreateSqliteStore do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:telegram_id, :integer, null: false)
      add(:first_name, :string)
      add(:username, :string)

      timestamps()
    end

    create(unique_index(:users, [:telegram_id]))

    create table(:memes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:meme_id, :string, null: false)
      add(:meme_unique_id, :string, null: false)
      add(:meme_type, :string, null: false)
      add(:last_used, :naive_datetime)

      add(
        :telegram_id,
        references(:users,
          column: :telegram_id,
          type: :integer,
          on_delete: :delete_all
        ),
        null: false
      )

      timestamps()
    end

    create(
      unique_index(:memes, [:meme_unique_id, :telegram_id], name: :meme_user_unique_index)
    )
  end
end
