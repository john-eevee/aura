defmodule Aura.Projects.DependencyParser do
  @moduledoc """
  Parses dependency manifest files from various package managers
  and extracts dependency information suitable for BOM entries.
  """

  @doc """
  Parses a dependency manifest file and returns a list of dependencies.

  ## Supported formats
  - mix.lock (Elixir)
  - package.json (Node.js)

  Returns `{:ok, [%{name: string, version: string}]}` on success,
  or `{:error, reason}` on failure.
  """
  def parse(content, filename) do
    case detect_format(filename) do
      :mix_lock -> parse_mix_lock(content)
      :package_json -> parse_package_json(content)
      :unknown -> {:error, :unsupported_format}
    end
  end

  defp detect_format(filename) do
    cond do
      String.ends_with?(filename, "mix.lock") -> :mix_lock
      String.ends_with?(filename, "package.json") -> :package_json
      true -> :unknown
    end
  end

  @doc """
  Parses an Elixir mix.lock file.
  
  Returns `{:ok, dependencies}` where dependencies is a list of maps with :name and :version keys.
  """
  def parse_mix_lock(content) do
    try do
      # Parse the Elixir term in mix.lock
      {result, _binding} = Code.eval_string(content)
      
      dependencies =
        result
        |> Enum.map(fn {name, details} ->
          version = extract_mix_version(details)
          %{name: to_string(name), version: version}
        end)
        |> Enum.filter(fn %{version: version} -> version != nil end)

      {:ok, dependencies}
    rescue
      e -> {:error, "Failed to parse mix.lock: #{Exception.message(e)}"}
    end
  end

  defp extract_mix_version({:hex, _package, version, _hash, _managers, _deps, _hex_metadata, _optional})
       when is_binary(version) do
    version
  end

  defp extract_mix_version({:hex, _package, version, _hash, _managers, _deps, _hex_metadata})
       when is_binary(version) do
    version
  end

  defp extract_mix_version({:hex, _package, version, _hash}) when is_binary(version) do
    version
  end

  defp extract_mix_version(_), do: nil

  @doc """
  Parses a Node.js package.json file.
  
  Returns `{:ok, dependencies}` where dependencies is a list of maps with :name and :version keys.
  """
  def parse_package_json(content) do
    case Jason.decode(content) do
      {:ok, json} ->
        dependencies =
          []
          |> add_dependencies(json["dependencies"])
          |> add_dependencies(json["devDependencies"])

        {:ok, dependencies}

      {:error, error} ->
        {:error, "Failed to parse package.json: #{inspect(error)}"}
    end
  end

  defp add_dependencies(acc, nil), do: acc

  defp add_dependencies(acc, deps) when is_map(deps) do
    new_deps =
      Enum.map(deps, fn {name, version} ->
        # Remove version prefixes like ^, ~
        clean_version = String.replace(version, ~r/^[\^~]/, "")
        %{name: name, version: clean_version}
      end)

    acc ++ new_deps
  end

  defp add_dependencies(acc, _), do: acc
end
