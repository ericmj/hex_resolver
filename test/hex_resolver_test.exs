defmodule HexResolverTest do
  use ExUnit.Case, async: true

  defp solve(request, registry) do
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

    HexResolver.solve(request, registry)
  end

  describe "without dependencies" do
    test "single package" do
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [])
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [{:bar, "1.0.0"}])
      assert {:error, _} = solve([{:foo, ">= 1.0.0"}], [{:foo, "0.1.0"}])

      assert solve([{:foo, ">= 0.0.0"}], [{:foo, "0.1.0"}]) == {:ok, %{foo: "0.1.0"}}
    end

    test "single with multiple packages" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.2.0"}]
      assert solve([{:foo, ">= 0.0.0"}], registry) == {:ok, %{foo: "0.1.0"}}
      assert solve([{:bar, ">= 0.0.0"}], registry) == {:ok, %{bar: "0.2.0"}}
    end

    test "multiple packages" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.1.0"}]
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}, {:bar, ">= 1.0.0"}], registry)
      assert {:error, _} = solve([{:foo, ">= 1.0.0"}, {:bar, ">= 0.0.0"}], registry)

      assert solve([{:foo, ">= 0.0.0"}, {:bar, ">= 0.0.0"}], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.1.0"}}
    end

    test "multiple versions of package" do
      assert solve([{:foo, ">= 0.0.0"}], [{:foo, "0.1.0"}, {:foo, "0.2.0"}]) == {:ok, %{foo: "0.2.0"}}
      assert solve([{:foo, ">= 0.0.0"}], [{:foo, "0.2.0"}, {:foo, "0.1.0"}]) == {:ok, %{foo: "0.2.0"}}
      assert solve([{:foo, "<= 0.1.0"}], [{:foo, "0.2.0"}, {:foo, "0.1.0"}]) == {:ok, %{foo: "0.1.0"}}
      assert solve([{:foo, "<= 0.1.0"}], [{:foo, "0.1.0"}, {:foo, "0.2.0"}]) == {:ok, %{foo: "0.1.0"}}
    end
  end

  describe "with dependencies" do
    test "single package" do
      registry = [{:foo, "0.1.0", [{:bar, ">= 0.0.0"}]}, {:bar, "0.2.0"}]

      assert solve([{:bar, ">= 0.0.0"}], registry) == {:ok, %{bar: "0.2.0"}}
      assert solve([{:foo, ">= 0.0.0"}], registry) == {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert solve([{:foo, ">= 0.0.0"}, {:bar, ">= 0.0.0"}], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert solve([{:bar, ">= 0.0.0"}, {:foo, ">= 0.0.0"}], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert {:error, _} = solve([{:foo, ">= 0.0.0"}, {:bar, ">= 1.0.0"}], registry)
    end

    test "transitive package" do
    end

    test "multiple versions of package" do
    end
  end
end
