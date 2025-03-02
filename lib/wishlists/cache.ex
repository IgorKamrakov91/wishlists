defmodule Wishlists.Cache do
  @table_name :wishlists_cache

  def start do
    :ets.new(@table_name, [:set, :public, :named_table])
  end

  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl)

    expires_at =
      case ttl do
        nil -> :infinity
        ttl when is_integer(ttl) -> System.system_time(:millisecond) + ttl
      end

    :ets.insert(@table_name, {key, value, expires_at})
  end

  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at}] ->
        cond do
          expires_at == :infinity ->
            value

          System.system_time(:millisecond) < expires_at ->
            value

          true ->
            :ets.delete(@table_name, key)
            nil
        end

      [] ->
        nil
    end
  end

  def delete(key) do
    :ets.delete(@table_name, key)
  end
end
