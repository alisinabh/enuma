defmodule Enuma do
  defmacro __using__(_env) do
    quote location: :keep do
      import Enuma
      @before_compile Enuma
    end
  end

  defmacro defenum(do: block) do
    quote location: :keep do
      Enuma.assert_no_items(__MODULE__)
      Module.register_attribute(__MODULE__, :enuma_defenum_items, accumulate: true)

      unquote(block)
    end
  end

  defmacro item(name, opts \\ []) do
    args = Keyword.get(opts, :args, []) |> List.wrap()
    opts = Keyword.put(opts, :args, Macro.escape(args))

    quote location: :keep do
      @enuma_defenum_items {unquote(name), unquote(opts)}
    end
  end

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
          elem(unquote(v), 0) == unquote(value)
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

        value = Keyword.get(opts, :value, item)

        generate_item_ast(item, args, value, opts)
      end

    item_keys = for {item, _opts} <- items, do: item

    items_map = Enum.into(items, %{})

    string_conversion_asts =
      for item <- item_keys do
        quote do
          def enuma_to_atom(unquote(Atom.to_string(item))) do
            {:ok, unquote(item)}
          end
        end
      end

    quote location: :keep do
      unquote_splicing(items_asts)

      unquote_splicing(string_conversion_asts)

      def enuma_to_atom(_invalid) do
        {:error, :invalid_enuma_value}
      end

      def enuma_to_atom!(atom) do
        case enuma_to_atom(atom) do
          {:ok, atom} -> atom
          {:error, :invalid_enuma_value} -> raise ArgumentError, message: "invalid enuma value"
        end
      end

      def enuma_items do
        unquote(item_keys)
      end

      def __items_map__ do
        unquote(Macro.escape(items_map))
      end

      def valid?(value) when is_atom(value) do
        value in enuma_items()
      end

      def valid?(value) when is_tuple(value) do
        [item_type | args] = Tuple.to_list(value)

        case Map.fetch(__items_map__(), item_type) do
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

      def valid?(_), do: false
    end
  end
end
