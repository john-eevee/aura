defmodule Aura.Storage.Behaviour do
  @moduledoc """
  Behaviour for pluggable storage adapters.

  This allows the system to support different storage backends like S3, Local filesystem, etc.
  """

  @doc """
  Stores a file and returns the storage path/key.

  ## Parameters
    - `file_path` - The local path to the file to store
    - `destination` - The destination path/key in the storage
    - `opts` - Additional options for the storage adapter
    
  ## Returns
    - `{:ok, stored_path}` - Success with the stored path
    - `{:error, reason}` - Failure with reason
  """
  @callback store(file_path :: String.t(), destination :: String.t(), opts :: Keyword.t()) ::
              {:ok, String.t()} | {:error, term()}

  @doc """
  Retrieves a file from storage.

  ## Parameters
    - `path` - The storage path/key
    - `opts` - Additional options for the storage adapter
    
  ## Returns
    - `{:ok, file_path}` - Success with the local file path
    - `{:error, reason}` - Failure with reason
  """
  @callback retrieve(path :: String.t(), opts :: Keyword.t()) ::
              {:ok, String.t()} | {:error, term()}

  @doc """
  Deletes a file from storage.

  ## Parameters
    - `path` - The storage path/key
    - `opts` - Additional options for the storage adapter
    
  ## Returns
    - `:ok` - Success
    - `{:error, reason}` - Failure with reason
  """
  @callback delete(path :: String.t(), opts :: Keyword.t()) :: :ok | {:error, term()}

  @doc """
  Streams a file from storage for viewing in browser.

  ## Parameters
    - `path` - The storage path/key
    - `opts` - Additional options for the storage adapter
    
  ## Returns
    - `{:ok, stream}` - Success with a stream
    - `{:error, reason}` - Failure with reason
  """
  @callback stream(path :: String.t(), opts :: Keyword.t()) ::
              {:ok, Enumerable.t()} | {:error, term()}
end
