defmodule Wishlists.Folders.CleanupWorker do
  use GenServer
  alias Wishlists.{Repo, Folders, Cards}
  alias Wishlists.Folders.Folder
  import Ecto.Query

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_cleanup()
    {:ok, state}
  end

  def handle_info(:cleanup, state) do
    cleanup_expired_folders()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, get_milliseconds_until_midnight())
  end

  defp get_milliseconds_until_midnight do
    now = DateTime.utc_now()
    tomorrow = DateTime.add(now, 1, :day)
    midnight = %{tomorrow | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    DateTime.diff(midnight, now, :millisecond)
  end

  defp cleanup_expired_folders do
    yesterday = Date.add(Date.utc_today(), -1)

    query =
      from f in Folder,
        where: not is_nil(f.event_date),
        where: f.event_date <= ^yesterday

    Repo.all(query)
    |> Enum.each(fn folder ->
      cleanup_folder(folder)
    end)
  end

  defp cleanup_folder(folder) do
    folder_cards = Cards.list_folder_cards(folder.id)

    Repo.transaction(fn ->
      reserved_card_ids =
        folder_cards
        |> Enum.filter(& &1.reservation)
        |> Enum.map(& &1.card_id)

      if length(reserved_card_ids) > 0 do
        from(c in Cards.Card, where: c.id in ^reserved_card_ids)
        |> Repo.delete_all()
      end

      Folders.delete_folder(folder)
    end)
  end
end
