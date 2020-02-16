defmodule HexResolver do
  def solve(request, registry) do
    registry =
      registry
      |> Enum.map(fn
        {package, version} -> {package, version, []}
        {package, version, deps} -> {package, version, deps}
      end)
      |> Enum.group_by(&elem(&1, 0), &{elem(&1, 1), elem(&1, 2)})
      |> Map.new(fn {package, versions} ->
        {package, Enum.sort_by(versions, &elem(&1, 0), {:desc, Version})}
      end)

    do_solve(request, registry)
  end

  def do_solve(requests, registry) do
    do_solve(requests, registry, %{})
  end

  defp do_solve([{request, requirement} | requests], registry, acc) do
    case Map.fetch(registry, request) do
      {:ok, versions} ->
        result =
          Enum.find(versions, fn {version, _deps} ->
            Version.match?(version, requirement)
          end)

        case result do
          {version, deps} ->
            # We may overwrite here!
            acc = Map.put(acc, request, version)
            do_solve(requests ++ deps, registry, acc)

          nil ->
            {:error, {:unsatisfied, request, requirement}}
        end

      :error ->
        {:error, {:unsatisfied, request, requirement}}
    end
  end

  defp do_solve([], _registry, acc) do
    {:ok, acc}
  end
end
