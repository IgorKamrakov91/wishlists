# TODO: remove this functionality
defmodule MarketplaceScrapper do
  require Logger

  @api_url "https://api.openai.com/v1/chat/completions"

  def fetch_and_extract(url) do
    case Req.get(url, finch: Wishlists.Finch) do
      {:ok, %Req.Response{body: html}} ->
        data = extract_relevant_data(html)

        case extract_data_from_html(data) do
          %{"title" => "", "description" => "", "image" => ""} ->
            {:error, :parse_failed}

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
      case Floki.find(document, "[itemprop=price], [class*='price'], [class*='Price']") do
        [] ->
          case Floki.find(document, "[aria-label='Итоговая цена']") do
            [] -> "0.0"
            elements -> Floki.text(elements) |> String.trim()
          end

        elements ->
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
    body = %{
      model: "gpt-5-nano",
      messages: [
        %{
          role: "system",
          content:
            "Ты парсер HTML, извлекай название, цену, описание товара и ссылку на изображение. Исправь адрес ссылки на изображение, если она не содержит протокола http или https, добавив их. Исправь название, если оно включает лишнюю информацию, кроме названия. И сократи название до 3 слов. Исправь цену, если она разделена пробелом и убери лишние символы."
        },
        %{role: "user", content: Jason.encode!(data)}
      ]
    }

    with api_key when is_binary(api_key) and api_key != "" <- System.get_env("OPENAI_API_KEY") do
      headers = [
        {"Authorization", "Bearer #{api_key}"},
        {"Content-Type", "application/json"}
      ]

      case Req.post(@api_url, json: body, headers: headers, finch: Wishlists.Finch) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          case body do
            %{"choices" => [%{"message" => %{"content" => content}}]} ->
              Jason.decode!(content)

            other ->
              Logger.warning("Unexpected marketplace parser response: #{inspect(other)}")
              :error
          end

        {:ok, %Req.Response{status: status}} ->
          Logger.warning("Marketplace parser request failed with status #{status}")
          :error

        {:error, reason} ->
          Logger.warning("Marketplace parser request failed: #{inspect(reason)}")
          :error
      end
    else
      _ ->
        Logger.warning("OPENAI_API_KEY is not configured for marketplace parser")

        :error
    end
  rescue
    error ->
      Logger.warning("Marketplace parser failed: #{Exception.message(error)}")
      :error
  end
end
