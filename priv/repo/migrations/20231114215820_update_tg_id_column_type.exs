defmodule MemeCacheBot.Repo.Migrations.UpdateTgIdColumnType do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :telegram_id, :bigint, from: :integer
    end

    alter table(:memes) do
      modify :telegram_id, :bigint, from: :integer
    end
  end
end
