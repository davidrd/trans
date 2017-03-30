alias Trans.Article
alias Trans.TestRepo, as: Repo

import Trans.Factory
import Trans.QueryBuilder
import Ecto.Query, only: [from: 2]

defmodule QueryBuilderTest do
  use ExUnit.Case

  setup_all do
    {:ok,
      translated_article: insert(:article),
      untranslated_article: insert(:article, translations: %{})
    }
  end

  test "should find only one article translated to ES" do
    count = Repo.one(from a in Article,
      where: not is_nil(translated(a, locale: :es)),
      select: count(a.id)
    )
    assert count == 1
  end

  test "should not find any article translated to DE" do
    count = Repo.one(from a in Article,
      where: not is_nil(translated(a, locale: :de)),
      select: count(a.id))
    assert count == 0
  end

  test "should find an article by its FR title",
  %{translated_article: article} do
    matches = Repo.all(from a in Article,
      where: translated(a.title, locale: :fr) == ^article.translations["fr"]["title"])
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by a non existant translation" do
    count = Repo.one(from a in Article,
      select: count(a.id),
      where: translated(a.title, locale: :es) == "FAKE TITLE")
    assert count == 0
  end

  test "should find an article by partial and case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["es"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> Kernel.<>("%")
    matches = Repo.all(from a in Article,
      where: ilike(translated(a.body, locale: :es), ^first_words))
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end

  test "should not find an article by incorrect case using case sensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
      |> Kernel.<>("%")
    count = Repo.one(from a in Article,
      select: count(a.id),
      where: like(translated(a.body, locale: :fr), ^first_words))
    assert count == 0
  end

  test "should find an article by incorrect case using case insensitive translation",
  %{translated_article: article} do
    first_words =
      article.translations["fr"]["body"]
      |> String.split
      |> Enum.take(3)
      |> Enum.join(" ")
      |> String.upcase
      |> Kernel.<>("%")
    matches = Repo.all(from a in Article,
      where: ilike(translated(a.body, locale: :fr), ^first_words))
    assert Enum.count(matches) == 1
    assert hd(matches).id == article.id
  end
end
