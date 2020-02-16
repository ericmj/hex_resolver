defmodule HexResolverTest do
  use ExUnit.Case, async: true
  import HexResolver

  describe "without dependencies" do
    test "single requirement, singlepackage" do
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [])
      assert {:error, _} = solve([{:foo, ">= 0.0.0"}], [{:bar, "1.0.0"}])
      assert {:error, _} = solve([{:foo, ">= 1.0.0"}], [{:foo, "0.1.0"}])

      assert solve([{:foo, ">= 0.0.0"}], [{:foo, "0.1.0"}]) == {:ok, %{foo: "0.1.0"}}
    end

    test "single requirement, multiple packages" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.2.0"}]
      assert solve([foo: ">= 0.0.0"], registry) == {:ok, %{foo: "0.1.0"}}
      assert solve([bar: ">= 0.0.0"], registry) == {:ok, %{bar: "0.2.0"}}
    end

    test "multiple requirements, multiple packages" do
      registry = [{:foo, "0.1.0"}, {:bar, "0.1.0"}]
      assert {:error, _} = solve([foo: ">= 0.0.0", bar: ">= 1.0.0"], registry)
      assert {:error, _} = solve([foo: ">= 1.0.0", bar: ">= 0.0.0"], registry)

      assert solve([{:foo, ">= 0.0.0"}, {:bar, ">= 0.0.0"}], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.1.0"}}
    end

    test "multiple versions of package" do
      assert solve([foo: ">= 0.0.0"], [{:foo, "0.1.0"}, {:foo, "0.2.0"}]) ==
               {:ok, %{foo: "0.2.0"}}

      assert solve([foo: ">= 0.0.0"], [{:foo, "0.2.0"}, {:foo, "0.1.0"}]) ==
               {:ok, %{foo: "0.2.0"}}

      assert solve([foo: "<= 0.1.0"], [{:foo, "0.2.0"}, {:foo, "0.1.0"}]) ==
               {:ok, %{foo: "0.1.0"}}

      assert solve([foo: "<= 0.1.0"], [{:foo, "0.1.0"}, {:foo, "0.2.0"}]) ==
               {:ok, %{foo: "0.1.0"}}
    end
  end

  describe "with dependencies" do
    test "single package" do
      registry = [{:foo, "0.1.0", [bar: ">= 0.0.0"]}, {:bar, "0.2.0"}]

      assert solve([bar: ">= 0.0.0"], registry) == {:ok, %{bar: "0.2.0"}}
      assert solve([foo: ">= 0.0.0"], registry) == {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert solve([foo: ">= 0.0.0", bar: ">= 0.0.0"], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert solve([bar: ">= 0.0.0", foo: ">= 0.0.0"], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0"}}

      assert {:error, _} = solve([foo: ">= 0.0.0", bar: ">= 1.0.0"], registry)
    end

    test "transitive package" do
      registry = [
        {:foo, "0.1.0", [bar: ">= 0.0.0"]},
        {:bar, "0.2.0", [baz: ">= 0.0.0"]},
        {:baz, "0.3.0"}
      ]

      assert solve([foo: ">= 0.0.0"], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0", baz: "0.3.0"}}

      assert solve([foo: ">= 0.0.0", baz: ">= 0.0.0"], registry) ==
               {:ok, %{foo: "0.1.0", bar: "0.2.0", baz: "0.3.0"}}

      assert {:error, _} = solve([foo: ">= 0.0.0", baz: ">= 1.0.0"], registry)
    end

    @tag :skip
    test "multiple versions of package" do
      registry = [
        {:foo, "0.1.0", [bar: ">= 0.0.0"]},
        {:bar, "0.2.0"},
        {:bar, "0.3.0"}
      ]

      assert solve([foo: ">= 0.0.0"], registry) == {:ok, %{foo: "0.1.0", bar: "0.3.0"}}
      assert solve([foo: ">= 0.0.0", bar: "== 0.2.0"], registry) == {:ok, %{foo: "0.1.0", bar: "0.2.0"}}
    end
  end
end
