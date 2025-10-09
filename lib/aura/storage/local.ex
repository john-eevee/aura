defmodule Aura.Storage.Local do
  @moduledoc """
  Local filesystem storage adapter.
  
  Stores files in a local directory on the filesystem.
  """

  @behaviour Aura.Storage.Behaviour

  @impl true
  def store(file_path, destination, opts \\ []) do
    base_path = opts[:base_path] || storage_path()
    full_destination = Path.join(base_path, destination)
    destination_dir = Path.dirname(full_destination)

    with :ok <- File.mkdir_p(destination_dir),
         :ok <- File.cp(file_path, full_destination) do
      {:ok, destination}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def retrieve(path, opts \\ []) do
    base_path = opts[:base_path] || storage_path()
    full_path = Path.join(base_path, path)

    if File.exists?(full_path) do
      {:ok, full_path}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def delete(path, opts \\ []) do
    base_path = opts[:base_path] || storage_path()
    full_path = Path.join(base_path, path)

    case File.rm(full_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def stream(path, opts \\ []) do
    base_path = opts[:base_path] || storage_path()
    full_path = Path.join(base_path, path)

    if File.exists?(full_path) do
      stream = File.stream!(full_path, [], 2048)
      {:ok, stream}
    else
      {:error, :not_found}
    end
  end

  defp storage_path do
    Application.get_env(:aura, :storage_path, "priv/storage")
  end
end
