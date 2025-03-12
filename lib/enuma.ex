defmodule Enuma do
  defmacro __using__(_env) do
    quote do
      import Enuma
      @before_compile Enuma
    end
  end

  defmacro defenum(items) do
    items =
      items
      |> Enum.map(fn
        {item, params} -> {item, Macro.escape(params)}
        item -> item
      end)

    quote do
      Enuma.assert_no_items(__MODULE__)
      @enuma_defenum_items unquote(items)
    end
  end

  def assert_no_items(module) do
    case Module.get_attribute(module, :enuma_defenum_items) do
      [] -> :ok
      nil -> :ok
      _ -> raise "Enuma: Cannot redefine already defined enum"
    end
  end

  defmacro __before_compile__(_env) do
    module = __CALLER__.module
    items = Module.get_attribute(module, :enuma_defenum_items)

    Enum.map(items, fn
      item when is_atom(item) ->
        quote do
          defmacro unquote(item)() do
            unquote(item)
          end

          defmacro unquote(String.to_atom("is_#{item}"))(v) do
            item = unquote(item)

            quote do
              unquote(v) == unquote(item)
            end
          end
        end

      {item, param_types} ->
        params_types = List.wrap(param_types)
        args = Macro.generate_arguments(Enum.count(params_types), __CALLER__.module)

        quote do
          defmacro unquote(item)(unquote_splicing(args)) do
            item = unquote(item)
            args = unquote(args)

            quote do
              {unquote(item), unquote_splicing(args)}
            end
          end

          defmacro unquote(String.to_atom("is_#{item}"))(v) do
            item = unquote(item)

            quote do
              elem(unquote(v), 0) == unquote(item)
            end
          end
        end
    end)
  end
end
