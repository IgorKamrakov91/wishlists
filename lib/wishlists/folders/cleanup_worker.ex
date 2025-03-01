defmodule Wishlists.Folders.CleanupWorker do
  use GenServer
  alias Wishlists.{Repo, Folders, Cards}
  alias Wishlists.Folders.Folder
  import Ecto.Query
  require Logger

  def start_link(opts) do
    if Application.get_env(:wishlists, :cleanup_worker_enabled, true) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    else
      :ignore
    end
  end

  def init(state) do
    Logger.info("Initializing CleanupWorker")
    Process.send(self(), :cleanup, [:noconnect])
    {:ok, state}
  end

  def handle_info(:cleanup, state) do
    Logger.info("Running cleanup task")
    cleanup_expired_folders()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    milliseconds = get_milliseconds_until_midnight()
    Logger.info("Scheduling next cleanup in #{milliseconds} milliseconds")
    Process.send_after(self(), :cleanup, milliseconds)
  end

  defp get_milliseconds_until_midnight do
    now = DateTime.utc_now()
    tomorrow = DateTime.add(now, 1, :day)
    midnight = %{tomorrow | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
    DateTime.diff(midnight, now, :millisecond)
  end

  defp cleanup_expired_folders do
    today = Date.utc_today()

    # notify_query =
    #   from f in Folder,
    #     where: not is_nil(f.event_date),
    #     where: f.event_date == ^today

    # notify_folders = Repo.all(notify_query)

    # notify_folders
    # |> Enum.each(fn folder ->
    #   folder_cards = Cards.list_folder_cards(folder.id)
    #   Wishlists.Email.EmailService.send_folder_cleanup_notification(folder, folder_cards)
    # end)

    cleanup_query =
      from f in Folder,
        where: not is_nil(f.event_date),
        where: f.event_date < ^today

    cleanup_folders = Repo.all(cleanup_query)

    cleanup_folders
    |> Enum.each(fn folder ->
      cleanup_folder(folder)
    end)
  end

  defp cleanup_folder(folder) do
    folder_cards = Cards.list_folder_cards(folder.id)
    Logger.info("Processing #{length(folder_cards)} cards in folder #{folder.id}")

    Repo.transaction(fn ->
      reserved_card_ids =
        folder_cards
        |> Enum.filter(& &1.reservation)
        |> Enum.map(& &1.card_id)

      Logger.info("Found #{length(reserved_card_ids)} reserved cards in folder #{folder.id}")

      if length(reserved_card_ids) > 0 do
        {deleted_count, _} =
          from(c in Cards.Card, where: c.id in ^reserved_card_ids)
          |> Repo.delete_all()

        Logger.info("Deleted #{deleted_count} reserved cards from folder #{folder.id}")
      end

      case Folders.delete_folder(folder) do
        {:ok, _} ->
          Logger.info("Successfully deleted folder #{folder.id}")

        {:error, reason} ->
          Logger.error("Failed to delete folder #{folder.id}: #{inspect(reason)}")
      end
    end)
  end
end
