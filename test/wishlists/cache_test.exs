defmodule Wishlists.CacheTest do
  use ExUnit.Case, async: false

  alias Wishlists.Cache

  setup_all do
    if :ets.whereis(:wishlists_cache) == :undefined do
      Cache.start()
    end

    :ok
  end

  setup do
    key = {__MODULE__, make_ref()}
    on_exit(fn -> Cache.delete(key) end)
    {:ok, key: key}
  end

  test "missing keys return nil", %{key: key} do
    assert Cache.get(key) == nil
  end

  test "values without a TTL remain available across reads", %{key: key} do
    value = %{items: ["Book", "Headphones"]}
    assert Cache.put(key, value)
    assert Cache.get(key) == value
    assert Cache.get(key) == value
  end

  test "false is preserved rather than treated as a cache miss", %{key: key} do
    Cache.put(key, false)
    assert Cache.get(key) == false
  end

  test "values remain available before their TTL expires", %{key: key} do
    Cache.put(key, "available", ttl: 60_000)
    assert Cache.get(key) == "available"
  end

  test "a zero TTL expires immediately and removes the entry", %{key: key} do
    Cache.put(key, "expired", ttl: 0)
    assert Cache.get(key) == nil
    assert :ets.lookup(:wishlists_cache, key) == []
  end

  test "a negative TTL is already expired", %{key: key} do
    Cache.put(key, "expired", ttl: -1)
    assert Cache.get(key) == nil
    assert :ets.lookup(:wishlists_cache, key) == []
  end

  test "overwriting an expired entry replaces its value and TTL", %{key: key} do
    Cache.put(key, "old", ttl: -1)
    Cache.put(key, "new")
    assert Cache.get(key) == "new"
  end

  test "deleting an entry is idempotent", %{key: key} do
    Cache.put(key, "value")
    assert Cache.delete(key)
    assert Cache.get(key) == nil
    assert Cache.delete(key)
  end
end
