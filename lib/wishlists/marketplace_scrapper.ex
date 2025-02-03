defmodule MarketplaceScrapper do
  @api_url "https://api.openai.com/v1/chat/completions"
  @api_key "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"

  # @scraping_bee_api_key "IQEIBGAEXIC1S753T4PHT39S6U1RHXCRXYP0YW8SPWTOOM270S5AH5SCSMMGMZZXBXCIZ4GJ8J4371VX"

  # @bright_data_api_key "8089960dc8eae23519d5da0e1e83e8912ca9acf29776cf72c15bc3dd5e23e32d"

  # @dataset_id "gd_luz4fboh2dicd27hhm"

  def fetch_and_extract(url) do
    {:error, :not_implemented}
  end

  def fetch_and_extract(url) do
    # 5 second delay
    Process.sleep(5000)

    {:ok,
     %{
       "description" => "Джемпер Mango ALMIBAR - белый",
       "image" => "https://a.lmcdn.ru/img600x866/R/T/RTLADP936901_24358938_1_v1.jpg",
       "price" => "0.0",
       "title" => "Джемпер Mango ALMIBAR"
     }}
  end

  # def fetch_and_extract(url) do
  #   case Req.get(url, finch: Wishlists.Finch) do
  #     {:ok, %Req.Response{body: html}} ->
  #       data = extract_relevant_data(html)

  #       IO.inspect(data, label: "DATA")

  #       case extract_data_from_html(data) do
  #         %{"title" => _, "description" => _, "image" => _} = extracted_data ->
  #           IO.inspect(extracted_data)
  #           {:ok, extracted_data}

  #         :error ->
  #           {:error, :api_failed}

  #         _ ->
  #           {:error, :parse_failed}
  #       end

  #     {:error, _reason} ->
  #       {:error, :fetch_failed}
  #   end
  # end

  # def fetch_and_extract(url) do
  #   headers = [
  #     {"Authorization", "Bearer #{@bright_data_api_key}"},
  #     {"Content-Type", "application/json"}
  #   ]

  #   body = [%{"url" => url}]

  #   # Укажи свой dataset_id
  #   dataset_id = "gd_luz4fboh2dicd27hhm"

  #   case Req.post(
  #          "https://api.brightdata.com/datasets/v3/trigger?dataset_id=#{dataset_id}&include_errors=true",
  #          headers: headers,
  #          json: body,
  #          finch: Wishlists.Finch
  #        ) do
  #     {:ok, %Req.Response{body: product_data} = response} ->
  #       IO.inspect(response, label: "FULL RESPONSE FROM BRIGHT DATA")
  #       {:ok, product_data}

  #     {:error, error} ->
  #       IO.inspect(error, label: "BRIGHT DATA ERROR")
  #       {:error, error}
  #   end
  # end

  defp extract_relevant_data(html) do
    {:ok, document} = Floki.parse_document(html)

    price_element = Floki.find(document, "[itemprop=price]")

    price =
      cond do
        price_element != [] ->
          Floki.attribute(price_element, "content") |> List.first()

        true ->
          case Floki.find(document, ".price, .product-price, .price-value") do
            [] ->
              case Floki.find(document, "[aria-label='Итоговая цена']") do
                [] -> "0.0"
                elements -> Floki.text(elements) |> String.trim()
              end

            elements ->
              Floki.text(elements) |> String.trim()
          end
      end

    image =
      case Floki.find(document, "img") do
        [] ->
          nil

        images ->
          images
          |> Enum.find(fn img -> Floki.attribute(img, "src") != [] end)
          |> case do
            nil -> nil
            img -> Floki.attribute(img, "src") |> List.first()
          end
      end

    %{
      title: Floki.find(document, "title") |> Floki.text(),
      price: price,
      description:
        Floki.find(document, "meta[name=description]")
        |> Floki.attribute("content")
        |> List.first() || "",
      image: image || ""
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
