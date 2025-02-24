defmodule Wishlists.Email.EmailTest do
  import Swoosh.Email
  require Logger
  alias Wishlists.Mailer

  def send_test_email(email, from_email \\ "onboarding@resend.dev") do
    Logger.info("Testing email configuration:")

    Logger.info(
      "RESEND_API_KEY: #{String.slice(System.get_env("RESEND_API_KEY") || "", 0..5)}..."
    )

    new()
    |> to(email)
    |> from({"Wishlists", from_email})
    |> subject("Test email from Wishlists")
    |> html_body("""
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h1>Hello from Wishlists!</h1>
        <p>This is a test email sent via Resend.</p>
      </div>
    """)
    |> text_body("Hello from Wishlists! This is a test email sent via Resend.")
    |> deliver()
  end

  defp deliver(email) do
    case Mailer.deliver(email) do
      {:ok, result} ->
        Logger.info("Email sent successfully: #{inspect(result)}")
        {:ok, result}

      {:error, reason} = error ->
        Logger.error("Failed to send email: #{inspect(reason)}")
        error
    end
  end
end
