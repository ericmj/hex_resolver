defmodule HexResolverTest do
  use ExUnit.Case, async: true
  import HexResolver

  defp assert_in(result, expected) do
    assert {:ok, actual} = result
    assert Enum.all?(expected, &(&1 in actual))
  end

  describe "without dependencies" do
    test "solve single" do
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [])
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [{:bar, "1.0.0"}])
      assert {:error, _} = solve([{:foo, ">= 1.0.0"}], [{:foo, "0.1.0"}])

      assert solve([{:foo, ">= 0.0.0"}], [{:foo, "0.1.0"}]) == {:ok, [{:foo, "0.1.0"}]}
    end

    test "solve single with multiple packages" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.2.0"}]
      assert solve([{:foo, ">= 0.0.0"}], registry) == {:ok, [{:foo, "0.1.0"}]}
      assert solve([{:bar, ">= 0.0.0"}], registry) == {:ok, [{:bar, "0.2.0"}]}
    end

    test "solve multiple" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.1.0"}]
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}, {:bar, ">= 1.0.0"}], registry)
      assert {:error, _} = solve([{:foo, ">= 1.0.0"}, {:bar, ">= 0.0.0"}], registry)

      assert_in(
        solve([{:foo, ">= 0.0.0"}, {:bar, ">= 0.0.0"}], registry),
        [{:foo, "0.1.0"}, {:bar, "0.1.0"}]
      )
    end
  end
end
