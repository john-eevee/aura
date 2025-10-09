defmodule Aura.Documents.Cleaner do
  @moduledoc """
  GenServer that periodically cleans up soft-deleted documents.
  
  Documents are permanently deleted after a configured period (default: 30 days).
  """

  use GenServer
  require Logger

  alias Aura.Documents

  @cleanup_interval :timer.hours(24)
  @days_after_deletion 30

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_documents()
    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_documents do
    days = Application.get_env(:aura, :document_cleanup_days, @days_after_deletion)
    documents = Documents.list_documents_for_cleanup(days)

    Logger.info("Starting document cleanup. Found #{length(documents)} documents to delete.")

    Enum.each(documents, fn document ->
      case Documents.delete_document_permanently(document) do
        :ok ->
          Logger.info("Permanently deleted document: #{document.id} (#{document.name})")

        {:error, reason} ->
          Logger.error(
            "Failed to delete document: #{document.id} (#{document.name}). Reason: #{inspect(reason)}"
          )
      end
    end)

    Logger.info("Document cleanup completed.")
  end
end
