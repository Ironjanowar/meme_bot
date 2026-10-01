defmodule MemeCacheBot.Store.MemeStore do
  @moduledoc false

  import Ecto.Query
  import MemeCacheBot.Store
  alias MemeCacheBot.Model.{Meme, MemeTag}
  alias MemeCacheBot.Repo

  def find_meme(opts \\ []) do
    Meme
    |> maybe_where_id(opts[:id])
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> maybe_where_meme_unique_id(opts[:meme_unique_id])
    |> maybe_preload(opts[:preload])
    |> maybe_limit(opts[:limit])
    |> Repo.one()
  end

  def find_memes(opts \\ []) do
    Meme
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> maybe_where_tags(opts[:tags])
    |> where_page(opts[:page])
    |> maybe_order_by(desc_nulls_last: :last_used)
    |> Repo.all()
  end

  def insert_meme(meme_params) do
    meme_params
    |> Map.new()
    |> Meme.insert_changeset()
    |> Repo.insert()
  end

  def count_memes(opts \\ []) do
    Meme
    |> maybe_where_telegram_id(opts[:telegram_id])
    |> Repo.aggregate(:count, :id)
  end

  def delete_meme(%Meme{} = meme), do: meme |> Map.from_struct() |> delete_meme()

  def delete_meme(%{telegram_id: telegram_id, meme_unique_id: meme_unique_id}) do
    case find_meme(telegram_id: telegram_id, meme_unique_id: meme_unique_id) do
      nil -> {:error, "Meme was not found"}
      meme -> Repo.delete(meme)
    end
  end

  def delete_meme(_), do: {:error, "Can not find meme with that params"}

  def update_meme(%Meme{} = meme, changes) do
    meme
    |> Meme.update_changeset(changes)
    |> Repo.update()
  end

  def replace_tags(%Meme{id: meme_id}, tags) when is_list(tags) do
    tags = Enum.uniq(tags)

    try do
      Repo.transaction(fn ->
        from(tag in MemeTag, where: tag.meme_id == ^meme_id) |> Repo.delete_all()

        Enum.each(tags, &insert_tag!(&1, meme_id))

        tags
      end)
    rescue
      error in Ecto.ConstraintError -> {:error, error}
    end
  end

  def list_tags(%Meme{id: meme_id}) do
    from(tag in MemeTag,
      where: tag.meme_id == ^meme_id,
      order_by: [asc: tag.tag],
      select: tag.tag
    )
    |> Repo.all()
  end

  # Private
  defp insert_tag!(tag, meme_id) do
    changeset = MemeTag.changeset(%MemeTag{}, %{meme_id: meme_id, tag: tag})

    case Repo.insert(changeset) do
      {:ok, _meme_tag} -> :ok
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end

  defp maybe_where_tags(query, nil), do: query
  defp maybe_where_tags(query, []), do: where(query, [meme], false)

  defp maybe_where_tags(query, tags) do
    query
    |> join(:inner, [meme], tag in MemeTag, on: tag.meme_id == meme.id)
    |> where([_meme, tag], tag.tag in ^tags)
    |> distinct(true)
  end

  defp where_page(query, nil), do: where_page(query, 0)

  defp where_page(query, page) do
    offset = page_to_offset(page)
    query |> limit(50) |> offset(^offset)
  end

  defp page_to_offset(page) when page <= 0, do: 0
  defp page_to_offset(page), do: (page - 1) * 50

  defp maybe_where_id(query, nil), do: query
  defp maybe_where_id(query, id) when is_binary(id), do: where(query, id: ^id)

  defp maybe_where_meme_unique_id(query, nil), do: query

  defp maybe_where_meme_unique_id(query, meme_unique_id) when is_binary(meme_unique_id),
    do: where(query, meme_unique_id: ^meme_unique_id)
end
