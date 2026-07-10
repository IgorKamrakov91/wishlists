defmodule Wishlists.Utils.SlugifyTest do
  use ExUnit.Case, async: true

  alias Wishlists.Utils.Slugify

  describe "slugify/1" do
    test "normalizes plain words to a lowercase slug" do
      assert Slugify.slugify("Birthday Gifts") == "birthday-gifts"
    end

    test "collapses repeated spaces and dashes" do
      assert Slugify.slugify("  Wedding   ideas -- 2026  ") == "wedding-ideas-2026"
    end

    test "removes unsupported punctuation" do
      assert Slugify.slugify("Phones, tablets & accessories!") == "phones-tablets-accessories"
    end
  end
end
