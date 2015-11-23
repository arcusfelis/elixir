import Kernel, except: [destructure: 2, defdelegate: 2, defstruct: 2]

defmodule Kernel.Utils do
  @moduledoc false

  def destructure(list, count) when is_list(list), do: destructure_list(list, count)
  def destructure(nil, count), do: destructure_nil(count)

  defp destructure_list(_, 0), do: []
  defp destructure_list([], count), do: destructure_nil(count)
  defp destructure_list([h|t], count), do: [h|destructure_list(t, count - 1)]

  defp destructure_nil(0), do: []
  defp destructure_nil(count), do: [nil|destructure_nil(count - 1)]

  def defdelegate(fun, opts) do
    append_first = Keyword.get(opts, :append_first, false)

    {name, args} =
      case Macro.decompose_call(fun) do
        {_, _} = pair -> pair
        _ -> raise ArgumentError, "invalid syntax in defdelegate #{Macro.to_string(fun)}"
      end

    check_defdelegate_args(args)

    as_args =
      case append_first and args != [] do
        true  -> tl(args) ++ [hd(args)]
        false -> args
      end

    as = Keyword.get(opts, :as, name)
    {name, args, as, as_args}
  end

  defp check_defdelegate_args([]),
    do: :ok
  defp check_defdelegate_args([{var, _, mod}|rest]) when is_atom(var) and is_atom(mod),
    do: check_defdelegate_args(rest)
  defp check_defdelegate_args([code|_]),
    do: raise(ArgumentError, "defdelegate/2 only accepts variable names, got: #{Macro.to_string(code)}")

  def defstruct(module, fields) do
    case fields do
      fs when is_list(fs) -> :ok
      other ->
        raise ArgumentError, "struct fields definition must be list, got: #{inspect other}"
    end

    fields = :lists.map(fn
      {key, val} when is_atom(key) ->
        try do
          Macro.escape(val)
        rescue
          e in [ArgumentError] ->
            raise ArgumentError, "invalid value for struct field #{key}, " <> Exception.message(e)
        else
          _ -> {key, val}
        end
      key when is_atom(key) ->
        {key, nil}
      other ->
        raise ArgumentError, "struct field names must be atoms, got: #{inspect other}"
    end, fields)

    :maps.put(:__struct__, module, :maps.from_list(fields))
  end
end
