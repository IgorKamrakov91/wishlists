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

  def fetch_and_extract(url) do
    case Req.get(url, finch: Wishlists.Finch) do
      {:ok, %Req.Response{body: html}} ->
        data = extract_relevant_data(html)

        IO.inspect(data, label: "DATA")

        case extract_data_from_html(data) do
          %{"title" => _, "description" => _, "image" => _} = extracted_data ->
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

  def extract_data_from_html(data) do
    IO.inspect(data, label: "Input Data")

    body = %{
      model: "gpt-3.5-turbo",
      messages: [
        %{
          role: "system",
          content:
            "Ты парсер HTML, извлекай название, цену, описание товара и ссылку на изображение. Исправь адрес ссылки на изображение, если она не содержит протокола http или https, добавив их. Исправь название, если оно включает лишнюю информацию, кроме названия. И сократи название до 3 слов. Исправь цену, если она разделена пробелом и убери лишние символы."
        },
        %{role: "user", content: Jason.encode!(data)}
      ]
    }

    IO.inspect(body, label: "Request Body")

    headers = [
      {"Authorization", "Bearer #{@api_key}"},
      {"Content-Type", "application/json"}
    ]

    IO.inspect(headers, label: "Request Headers")

    case Req.post(@api_url, json: body, headers: headers, finch: Wishlists.Finch) do
      {:ok, %Req.Response{status: status, body: body} = _response} ->
        IO.inspect(status, label: "Response Status")
        IO.inspect(body, label: "Response Body")

        case body do
          %{"choices" => [%{"message" => %{"content" => content}}]} ->
            IO.inspect(content, label: "GPT Content")
            parsed = Jason.decode!(content)
            IO.inspect(parsed, label: "Parsed Content")
            parsed

          other ->
            IO.inspect(other, label: "Unexpected Response Format")
            :error
        end

      {:error, %Req.Response{status: status} = response} ->
        IO.inspect(status, label: "Error Status")
        IO.inspect(response, label: "Error Response")
        :error

      {:error, reason} ->
        IO.inspect(reason, label: "Request Error")
        :error
    end
  rescue
    error ->
      IO.inspect(error, label: "Rescue Error")
      :error
  end
end
