defmodule Enuma.EctoTest do
  use ExUnit.Case

  alias MessageEnum
  alias MessageEnumSchema
  import Ecto.Changeset

  # Helper function to create a parameterized type for testing
  defp type_with_ecto_type(ecto_type) do
    %{type: MessageEnum, ecto_type: ecto_type}
  end

  describe "cast/2" do
    test "casts valid atom value" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: :quit}, [:type])

      assert changeset.valid?
      assert get_change(changeset, :type) == :quit
    end

    test "casts valid tuple value with map args" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: {:move, %{x: 1, y: 2}}}, [:type])

      assert changeset.valid?
      assert get_change(changeset, :type) == {:move, %{x: 1, y: 2}}
    end

    test "casts valid tuple value with string args" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: {:write, "hello"}}, [:type])

      assert changeset.valid?
      assert get_change(changeset, :type) == {:write, "hello"}
    end

    test "casts valid tuple value with list args" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: {:change_color, 255, 0, 0}}, [:type])

      assert changeset.valid?
      assert get_change(changeset, :type) == {:change_color, 255, 0, 0}
    end

    test "returns error for invalid atom value" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: :invalid}, [:type])

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:type]
    end

    test "returns error for invalid tuple value" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: {:move, "invalid"}}, [:type])

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:type]
    end

    test "returns error for completely invalid value" do
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: 123}, [:type])

      refute changeset.valid?
      assert {"is invalid", _} = changeset.errors[:type]
    end
  end

  describe "dump/3 with :string type" do
    test "dumps atom value to string" do
      value = :quit
      assert {:ok, "quit"} = Enuma.Ecto.dump(value, nil, type_with_ecto_type(:string))
    end

    test "returns error when dumping complex types to string" do
      # The implementation in Enuma.Helpers.to_string/1 explicitly returns an error
      # for tuple values, as complex types are not supported in string format

      # Test with map args
      value = {:move, %{x: 1, y: 2}}
      assert {:error, :unsupported_enuma_ecto_type} = Enuma.Ecto.dump(value, nil, type_with_ecto_type(:string))

      # Test with string args
      value = {:write, "hello"}
      assert {:error, :unsupported_enuma_ecto_type} = Enuma.Ecto.dump(value, nil, type_with_ecto_type(:string))

      # Test with list args
      value = {:change_color, 255, 0, 0}
      assert {:error, :unsupported_enuma_ecto_type} = Enuma.Ecto.dump(value, nil, type_with_ecto_type(:string))
    end
  end

  describe "dump/3 with :map type" do
    test "dumps atom value to map" do
      value = :quit

      assert {:ok, %{"key" => "quit", "values" => []}} =
               Enuma.Ecto.dump(value, nil, type_with_ecto_type(:map))
    end

    test "dumps tuple value with map args to map" do
      value = {:move, %{x: 1, y: 2}}

      assert {:ok, %{"key" => "move", "values" => [%{x: 1, y: 2}]}} =
               Enuma.Ecto.dump(value, nil, type_with_ecto_type(:map))
    end

    test "dumps tuple value with string args to map" do
      value = {:write, "hello"}

      assert {:ok, %{"key" => "write", "values" => ["hello"]}} =
               Enuma.Ecto.dump(value, nil, type_with_ecto_type(:map))
    end

    test "dumps tuple value with list args to map" do
      value = {:change_color, 255, 0, 0}

      assert {:ok, %{"key" => "change_color", "values" => [255, 0, 0]}} =
               Enuma.Ecto.dump(value, nil, type_with_ecto_type(:map))
    end
  end

  describe "load/3 with :string type" do
    test "loads atom value from string" do
      value = "quit"
      assert {:ok, :quit} = Enuma.Ecto.load(value, nil, type_with_ecto_type(:string))
    end

    test "returns error for complex types in string format" do
      # Since complex types are not supported in string format, any string that looks like
      # it might be a complex type should return an error
      value = "move:x=1,y=2"
      assert {:error, :invalid_enuma_value} = Enuma.Ecto.load(value, nil, type_with_ecto_type(:string))
    end

    test "returns error for invalid string format" do
      value = "invalid_enum"
      assert {:error, :invalid_enuma_value} = Enuma.Ecto.load(value, nil, type_with_ecto_type(:string))
    end
  end

  describe "load/3 with :map type" do
    test "loads atom value from map" do
      value = %{"key" => "quit", "values" => []}
      assert {:ok, :quit} = Enuma.Ecto.load(value, nil, type_with_ecto_type(:map))
    end

    test "loads tuple value with map args from map" do
      value = %{"key" => "move", "values" => [%{"x" => 1, "y" => 2}]}

      assert {:ok, {:move, %{"x" => 1, "y" => 2}}} =
               Enuma.Ecto.load(value, nil, type_with_ecto_type(:map))
    end

    test "loads tuple value with string args from map" do
      value = %{"key" => "write", "values" => ["hello"]}
      assert {:ok, {:write, "hello"}} = Enuma.Ecto.load(value, nil, type_with_ecto_type(:map))
    end

    test "loads tuple value with list args from map" do
      value = %{"key" => "change_color", "values" => [255, 0, 0]}

      assert {:ok, {:change_color, 255, 0, 0}} =
               Enuma.Ecto.load(value, nil, type_with_ecto_type(:map))
    end

    test "returns error for invalid map format" do
      value = %{"invalid" => "format"}

      assert {:error, :invalid_dumped_value} =
               Enuma.Ecto.load(value, nil, type_with_ecto_type(:map))
    end
  end

  describe "equal?/3" do
    test "compares equal values" do
      value1 = :quit
      value2 = :quit
      assert Enuma.Ecto.equal?(value1, value2, type_with_ecto_type(:string))

      value1 = {:move, %{x: 1, y: 2}}
      value2 = {:move, %{x: 1, y: 2}}
      assert Enuma.Ecto.equal?(value1, value2, type_with_ecto_type(:string))
    end

    test "compares unequal values" do
      value1 = :quit
      value2 = {:move, %{x: 1, y: 2}}
      refute Enuma.Ecto.equal?(value1, value2, type_with_ecto_type(:string))

      value1 = {:move, %{x: 1, y: 2}}
      value2 = {:move, %{x: 2, y: 1}}
      refute Enuma.Ecto.equal?(value1, value2, type_with_ecto_type(:string))
    end
  end

  describe "integration with Ecto schema" do
    test "can be used in an Ecto schema" do
      schema = %MessageEnumSchema{}
      assert schema.__struct__ == MessageEnumSchema
      assert Map.has_key?(schema, :type)
    end

    test "validates data in an Ecto changeset" do
      import Ecto.Changeset

      # Create a changeset with valid data
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: :quit}, [:type])
        |> validate_required([:type])

      assert changeset.valid?

      # Create a changeset with invalid data
      changeset =
        %MessageEnumSchema{}
        |> cast(%{type: :invalid_enum}, [:type])
        |> validate_required([:type])

      refute changeset.valid?
    end
  end
end
