defmodule MarketplaceScrapper do
  @api_url "https://api.openai.com/v1/chat/completions"
  @api_key "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"

  def fetch_and_extract(url) do

    Process.sleep(5000)  # 5 second delay
    {:ok,
     %{
       "description" =>
         "Крем для рук The Act серия XX, Увлажняющий и питательный, 65мл, цвет: прозрачный. Бесплатная доставка по России!",
       "image" => "https://a.lmcdn.ru/img600x866/M/P/MP002XU0CXFI_21050626_1_v2.jpg",
       "price" => "1123",
       "title" => "Крем для рук The Act серия XX, Увлажняющий и питательный, 65мл"
     }}
  end

  def fetch_and_extract(url) do
    case Req.get(url, finch: Wishlists.Finch) do
      {:ok, %Req.Response{body: html}} ->
        data = extract_relevant_data(html)

        case extract_data_from_html(data) do
          %{"title" => _, "description" => _, "image" => _} = extracted_data ->
            IO.inspect(extracted_data)
            {:ok, extracted_data}

          :error ->
            {:error, :api_failed}

          _ ->
            {:error, :parse_failed}
        end

      {:error, _reason} ->
        {:error, :fetch_failed}
    end
  end

  defp extract_relevant_data(html) do
    {:ok, document} = Floki.parse_document(html)

    %{
      title: Floki.find(document, "title") |> Floki.text(),
      price:
        Floki.find(document, "[itemprop=price]") |> Floki.attribute("content") |> List.first() ||
          Floki.find(document, ".price, .product-price, .price-value")
          |> Floki.text()
          |> String.trim() ||
          Floki.find(document, "[aria-label='Итоговая цена']") |> Floki.text() |> String.trim() ||
          0.0,
      description:
        Floki.find(document, "meta[name=description]")
        |> Floki.attribute("content")
        |> List.first(),
      image:
        Floki.find(document, "img")
        |> Enum.find(fn img -> Floki.attribute(img, "src") != [] end)
        |> Floki.attribute("src")
        |> List.first()
    }
  end

  defp extract_data_from_html(data) do
    body = %{
      model: "gpt-3.5-turbo",
      messages: [
        %{
          role: "system",
          content:
            "Ты парсер HTML, извлекай название, цену, описание товара и ссылку на изображение. Исправь адрес ссылки на изображение, если она некорректная. Исправь название, если оно включает лишнюю информацию, кроме названия. И сократи название до 3 слов."
        },
        %{role: "user", content: Jason.encode!(data)}
      ]
    }

    headers = [
      {"Authorization", "Bearer #{@api_key}"},
      {"Content-Type", "application/json"}
    ]

    case Req.post(@api_url, json: body, headers: headers, finch: Wishlists.Finch) do
      {:ok, %Req.Response{body: %{"choices" => [%{"message" => %{"content" => content}}]}}} ->
        Jason.decode!(content)

      {:error, _reason} ->
        :error
    end
  rescue
    _ -> :error
  end
end
