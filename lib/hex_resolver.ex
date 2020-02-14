defmodule HexResolver do
  def solve(requests, registry) do
    solve(requests, registry, %{})
  end

  defp solve([{request, requirement} | requests], registry, acc) do
    case Map.fetch(registry, request) do
      {:ok, versions} ->
        result =
          Enum.find(versions, fn {version, _deps} ->
            Version.match?(version, requirement)
          end)

        case result do
          {version, deps} ->
            acc = Map.put(acc, request, version)
            solve(requests ++ deps, registry, acc)

          nil ->
            {:error, {:unsatisfied, request, requirement}}
        end

      :error ->
        {:error, {:unsatisfied, request, requirement}}
    end
  end

  defp solve([], _registry, acc) do
    {:ok, acc}
  end
end
