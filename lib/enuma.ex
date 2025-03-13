defmodule Enuma do
  @moduledoc """
  Enuma is a library for defining and working with Rust like Enums in Elixir.

  ### Example

  ```elixir
  defmodule MyEnum do
    use Enuma

    defenum do
      item :foo
      item :bar, args: [integer()]
      item :baz, args: [String.t()]
    end
  end
  ```

  Enuma will create macros for each item, allowing you to match on the enum values and check if a value is of a specific type.

  ```elixir
  iex> require MyEnum
  MyEnum

  iex> MyEnum.foo() = :foo
  true

  iex> MyEnum.bar(x) = {:bar, 1}
  {:bar, 1}
  ```
  """

  defmacro __using__(_env) do
    quote location: :keep do
      import Enuma
      @before_compile Enuma
    end
  end

  @doc """
  Defines an enum with the given items.
  """
  defmacro defenum(do: block) do
    quote location: :keep do
      Enuma.assert_no_items(__MODULE__)
      Module.register_attribute(__MODULE__, :enuma_defenum_items, accumulate: true)

      unquote(block)
    end
  end

  @doc """
  Defines an item with the given name and options.

  ## Options
    * `:args` - a list of arguments to be passed to the item macro
  """
  defmacro item(name, opts \\ []) do
    args = Keyword.get(opts, :args, []) |> List.wrap()
    opts = Keyword.put(opts, :args, Macro.escape(args))

    quote location: :keep do
      @enuma_defenum_items {unquote(name), unquote(opts)}
    end
  end

  def from_string(value, type_module) do
    case Map.fetch(type_module.__enuma_string_mappings__(), value) do
      {:ok, atom} -> {:ok, atom}
      :error -> {:error, :invalid_enuma_value}
    end
  end

  def from_string!(value, type_module) do
    case from_string(value, type_module) do
      {:ok, atom} -> atom
      {:error, :invalid_enuma_value} -> raise "Enuma: Invalid enum value"
    end
  end

  def to_string(key, type_module) when is_atom(key) do
    case Map.fetch(type_module.__enuma_atom_mappings__(), key) do
      {:ok, string} -> {:ok, string}
      :error -> {:error, :invalid_enuma_value}
    end
  end

  def to_string(value, _type_module) when is_tuple(value) do
    {:error, :unsupported_enuma_ecto_type}
  end

  def valid?(value, type_module) when is_atom(value) do
    value in type_module.__enuma_items__()
  end

  def valid?(nil, _type_module), do: true

  def valid?(value, type_module) when is_tuple(value) do
    [item_type | args] = Tuple.to_list(value)

    case Map.fetch(type_module.__enuma_items_map__(), item_type) do
      {:ok, item} ->
        arg_types = Keyword.fetch!(item, :args)

        # Fast-fail: check argument count first
        if Enum.count(args) != Enum.count(arg_types) do
          false
        else
          # Check each argument matches expected type
          Enum.zip(arg_types, args)
          |> Enum.all?(fn {type, arg} ->
            Enuma.Helpers.type_match?(arg, type)
          end)
        end

      :error ->
        false
    end
  end

  def valid?(_, _type_module), do: false

  @doc false
  def assert_no_items(module) do
    case Module.get_attribute(module, :enuma_defenum_items) do
      [] -> :ok
      nil -> :ok
      _ -> raise "Enuma: Cannot redefine already defined enum"
    end
  end

  defp generate_item_ast(item, _args = [], value, _opts) do
    quote location: :keep do
      defmacro unquote(item)() do
        value = unquote(value)

        quote location: :keep do
          unquote(value)
        end
      end

      defmacro unquote(String.to_atom("is_#{item}"))(v) do
        value = unquote(value)

        quote location: :keep do
          unquote(v) == unquote(value)
        end
      end
    end
  end

  defp generate_item_ast(item, args, value, _opts) do
    quote location: :keep do
      defmacro unquote(item)(unquote_splicing(args)) do
        value = unquote(value)
        args = unquote(args)

        quote location: :keep do
          {unquote(value), unquote_splicing(args)}
        end
      end

      defmacro unquote(String.to_atom("is_#{item}"))(v) do
        value = unquote(value)

        quote location: :keep do
          is_tuple(unquote(v)) and elem(unquote(v), 0) == unquote(value)
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    module = __CALLER__.module

    items = Module.get_attribute(module, :enuma_defenum_items)

    items_asts =
      for {item, opts} <- items do
        {args, opts} = Keyword.pop!(opts, :args)

        args =
          args
          |> List.wrap()
          |> Enum.count()
          |> Macro.generate_arguments(__CALLER__.module)

        generate_item_ast(item, args, item, opts)
      end

    item_keys = for {item, _opts} <- items, do: item

    items_map = Enum.into(items, %{})

    string_conversion_mapping =
      item_keys
      |> Enum.map(&{Atom.to_string(&1), &1})
      |> Enum.into(%{})
      |> Macro.escape()

    atom_conversion_mapping =
      item_keys
      |> Enum.map(&{&1, Atom.to_string(&1)})
      |> Enum.into(%{})
      |> Macro.escape()

    quote location: :keep do
      unquote_splicing(items_asts)

      def __enuma_string_mappings__ do
        unquote(string_conversion_mapping)
      end

      def __enuma_atom_mappings__ do
        unquote(atom_conversion_mapping)
      end

      def __enuma_items__ do
        unquote(item_keys)
      end

      def __enuma_items_map__ do
        unquote(Macro.escape(items_map))
      end
    end
  end
end
