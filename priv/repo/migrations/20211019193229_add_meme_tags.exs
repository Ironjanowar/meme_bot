defmodule MemeCacheBot.Repo.Migrations.AddMemeTags do
  use Ecto.Migration

  def change do
    alter table(:memes) do
      add :tags, {:array, :string}
    end
  end
end
