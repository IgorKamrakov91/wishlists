defmodule MarketplaceScrapper do
  @api_url "https://api.openai.com/v1/chat/completions"
  @api_key "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"

  # def fetch_and_extract(url) do
  #   {:error, :not_implemented}
  # end

  # def fetch_and_extract(url) do
  #   # 5 second delay
  #   Process.sleep(5000)

  #   {:ok,
  #    %{
  #      "description" => "Джемпер Mango ALMIBAR - белый",
  #      "image" => "https://a.lmcdn.ru/img600x866/R/T/RTLADP936901_24358938_1_v1.jpg",
  #      "price" => "0.0",
  #      "title" => "Джемпер Mango ALMIBAR"
  #    }}
  # end

  def fetch_and_extract(url, opts \\ []) do
    retry_opts = [
      max_attempts: Keyword.get(opts, :max_attempts, 3),
      base_delay: Keyword.get(opts, :base_delay, 1000),
      max_delay: Keyword.get(opts, :max_delay, 5000)
    ]

    Req.new(url: url)
    |> Req.Request.put_options(retry: retry_opts, receive_timeout: 15_000)
    |> Req.get(finch: Wishlists.Finch)
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{body: html}}) do
    with {:ok, data} <- extract_relevant_data(html),
         {:ok, extracted} <- extract_data_from_html(data) do
      {:ok, extracted}
    end
  end

  defp handle_response({:error, reason}), do: {:error, {:fetch_failed, reason}}

  defp extract_relevant_data(html) do
    {:ok, document} = Floki.parse_document(html)

    # Combine both searches
    price =
      case Floki.find(document, "[itemprop=price], [class*='price'], [class*='Price'") do
        [] ->
          case Floki.find(document, "[aria-label='Итоговая цена']") do
            [] -> "0.0"
            elements -> Floki.text(elements) |> String.trim()
          end

        elements ->
          IO.inspect(elements, label: "elements")

          elements
          |> Enum.map(fn element ->
            cond do
              Floki.attribute(element, "content") != [] ->
                Floki.attribute(element, "content") |> List.first()

              true ->
                Floki.text(element) |> String.trim()
            end
          end)
          |> Enum.reject(&(&1 == ""))
          |> List.first() || "0.0"
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
            "Ты парсер HTML, извлекай название, цену, описание товара и ссылку на изображение. Исправь адрес ссылки на изображение, если она некорректная. Исправь название, если оно включает лишнюю информацию, кроме названия. И сократи название до 3 слов. Исправь цену, если она разделена пробелом и убери лишние символы."
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
