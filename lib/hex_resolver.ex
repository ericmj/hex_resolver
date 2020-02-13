defmodule HexResolver do
  def solve(requests, registry) do
    solve(requests, registry, [])
  end

  defp solve([{request, requirement} | requests], registry, acc) do
    version =
      Enum.find_value(registry, fn
        {^request, version} ->
          Version.match?(version, requirement) && version

        {_package, _version} ->
          nil
      end)

    if version do
      solve(requests, registry, [{request, version} | acc])
    else
      {:error, {:unsatisfied, request, requirement}}
    end
  end

  defp solve([], _registry, acc) do
    {:ok, acc}
  end
end
