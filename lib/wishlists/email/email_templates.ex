defmodule Wishlists.Email.EmailTemplates do
  import Swoosh.Email
  use Gettext, backend: WishlistsWeb.Gettext

  def welcome_email(user) do
    new()
    |> to({user.email, user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject(gettext("Welcome to Wishlists!"))
    |> html_body(welcome_html_body(user))
    |> text_body(welcome_text_body(user))
  end

  def reservation_notification(folder, folder_card, reserver_name) do
    folder =
      if Ecto.assoc_loaded?(folder.user) do
        folder
      else
        Wishlists.Repo.preload(folder, :user)
      end

    new()
    |> to({folder.user.email, folder.user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject(gettext("New Reservation in Your Wishlist!"))
    |> html_body(reservation_html_body(folder, folder_card, reserver_name))
    |> text_body(reservation_text_body(folder, folder_card, reserver_name))
  end

  def reset_password_email(user) do
    new()
    |> to({user.email, user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject(gettext("Reset Your Password"))
    |> html_body(reset_password_html_body(user))
    |> text_body(reset_password_text_body(user))
  end

  defp welcome_html_body(user) do
    """
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); padding: 32px;">
      <div style="text-align: center; margin-bottom: 32px;">
        <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; letter-spacing: -0.5px;">
          #{gettext("Welcome to Wishlists!")}
        </div>
      </div>

      <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 2px; border-radius: 12px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 10px; padding: 24px;">
          <p style="color: #1f2937; font-size: 18px; margin-bottom: 16px;">#{gettext("Hi")} #{user.email},</p>
          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px;">#{gettext("Thank you for joining Wishlists! We're excited to help you manage your wishes and share them with friends and family.")}</p>
          <p style="color: #4b5563; line-height: 1.6; font-weight: 500;">#{gettext("Get started by creating your first wishlist!")}</p>
        </div>
      </div>

      <div style="text-align: center; margin: 32px 0;">
        <a href="#{WishlistsWeb.Endpoint.url()}/dashboard"
           style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 32px; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.3);">
          #{gettext("Go to Dashboard")} ✨
        </a>
      </div>

      <div style="text-align: center; border-top: 1px solid #e5e7eb; padding-top: 24px; margin-top: 32px;">
        <p style="color: #6b7280; font-size: 16px; margin-bottom: 8px;">#{gettext("Happy wishing!")} 🌟</p>
        <p style="color: #4f46e5; font-weight: 600; font-size: 14px;">#{gettext("The Wishlists Team")}</p>
      </div>
    </div>
    """
  end

  defp welcome_text_body(user) do
    """
    ✨ #{gettext("Welcome to Wishlists!")} ✨

    #{gettext("Hi")} #{user.email},

    #{gettext("Thank you for joining Wishlists! We're excited to help you manage your wishes and share them with friends and family.")}

    #{gettext("Get started by creating your first wishlist!")}

    #{gettext("Visit our Dashboard:")} #{WishlistsWeb.Endpoint.url()}/dashboard

    #{gettext("Happy wishing!")} 🌟

    #{gettext("Best wishes")},
    #{gettext("The Wishlists Team")}
    """
  end

  defp reservation_html_body(folder, folder_card, reserver_name) do
    reserver_info =
      if folder.show_reserver_names do
        "<p style=\"margin: 10px 0;\"><strong>#{gettext("Reserved by")}:</strong> #{reserver_name}</p>"
      else
        "<p style=\"margin: 10px 0;\">#{gettext("Someone has reserved this item")}</p>"
      end

    """
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h1 style="color: #4f46e5;">#{gettext("New Reservation!")}</h1>
      <p>#{gettext("Hi")} #{folder.user.email},</p>
      <p>#{gettext("Great news! Someone has reserved an item from your wishlist")} "#{folder.name}".</p>
      <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <p style="margin: 0;"><strong>#{gettext("Item")}:</strong> #{folder_card.card.title}</p>
        #{reserver_info}
      </div>
      <div style="margin: 30px 0;">
        <a href="#{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}"
           style="background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">
          #{gettext("View Wishlist")}
        </a>
      </div>
      <p>#{gettext("Best wishes")},</p>
      <p>#{gettext("The Wishlists Team")}</p>
      <div style="margin-top: 20px; padding-top: 20px; border-top: 1px solid #e5e7eb; font-size: 12px; color: #6b7280;">
        <p>#{gettext("To unsubscribe from reservation notifications, click the \"Unsubscribe\" link.")}</p>
      </div>
    </div>
    """
  end

  defp reservation_text_body(folder, folder_card, reserver_name) do
    reserver_info =
      if folder.show_reserver_names do
        "#{gettext("Reserved by")}: #{reserver_name}"
      else
        gettext("Someone has reserved this item.")
      end

    """
    #{gettext("New Reservation!")}

    #{gettext("Hi")} #{folder.user.email},

    #{gettext("Great news! Someone has reserved an item from your wishlist")} "#{folder.name}".

    #{gettext("Item")}: #{folder_card.card.title}
    #{reserver_info}

    #{gettext("View your wishlist")}: #{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}

    #{gettext("Best wishes")},
    #{gettext("The Wishlists Team")}

    ---
    #{gettext("To unsubscribe from reservation notifications, use the \"Unsubscribe\" link.")}
    """
  end

  defp reset_password_html_body(user) do
    reset_url = "#{WishlistsWeb.Endpoint.url()}/reset-password/#{user.reset_password_token}"

    """
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); padding: 32px;">
      <div style="text-align: center; margin-bottom: 32px;">
        <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; letter-spacing: -0.5px;">
          #{gettext("Reset Your Password")}
        </div>
      </div>

      <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 2px; border-radius: 12px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 10px; padding: 24px;">
          <p style="color: #1f2937; font-size: 18px; margin-bottom: 16px;">#{gettext("Hi")} #{user.email},</p>
          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px;">#{gettext("You requested to reset your password. Click the button below to set a new password.")}</p>
          <p style="color: #4b5563; line-height: 1.6; font-weight: 500;">#{gettext("This link will expire in 24 hours.")}</p>
        </div>
      </div>

      <div style="text-align: center; margin: 32px 0;">
        <a href="#{reset_url}"
           style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 32px; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.3);">
          #{gettext("Reset Password")} 🔐
        </a>
      </div>

      <div style="text-align: center; border-top: 1px solid #e5e7eb; padding-top: 24px; margin-top: 32px;">
        <p style="color: #6b7280; font-size: 16px; margin-bottom: 8px;">#{gettext("If you didn't request this, please ignore this email.")}</p>
        <p style="color: #4f46e5; font-weight: 600; font-size: 14px;">#{gettext("The Wishlists Team")}</p>
      </div>
    </div>
    """
  end

  defp reset_password_text_body(user) do
    reset_url = "#{WishlistsWeb.Endpoint.url()}/reset-password/#{user.reset_password_token}"

    """
    🔐 #{gettext("Reset Your Password")}

    #{gettext("Hi")} #{user.email},

    #{gettext("You requested to reset your password. Visit the following link to set a new password:")}

    #{reset_url}

    #{gettext("This link will expire in 24 hours.")}

    #{gettext("If you didn't request this, please ignore this email.")}

    #{gettext("Best wishes")},
    #{gettext("The Wishlists Team")}
    """
  end

  def folder_cleanup_notification(user, folder, folder_cards) do
    unreserved_cards = Enum.reject(folder_cards, & &1.reservation)

    new()
    |> to({user.email, user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject(gettext("Your Wishlist Will Be Archived Soon"))
    |> html_body(folder_cleanup_html_body(user, folder, unreserved_cards))
    |> text_body(folder_cleanup_text_body(user, folder, unreserved_cards))
  end

  defp folder_cleanup_html_body(user, folder, unreserved_cards) do
    celebration_message = get_celebration_message(folder.event_type)

    """
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); padding: 32px;">
      <div style="text-align: center; margin-bottom: 32px;">
        <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; letter-spacing: -0.5px;">
          #{celebration_message.title}
        </div>
      </div>

      <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 2px; border-radius: 12px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 10px; padding: 24px;">
          <p style="color: #1f2937; font-size: 18px; margin-bottom: 16px;">#{gettext("Hi")} #{user.email},</p>

          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px; font-size: 18px;">
            #{celebration_message.text} #{celebration_message.emoji}
          </p>

          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px;">
            #{gettext("As the event has passed, your wishlist")} "#{folder.name}" #{gettext("will be archived soon.")}
          </p>
          #{if length(unreserved_cards) > 0 do
      """
      <p style="color: #4b5563; line-height: 1.6;">
        #{length(unreserved_cards)} #{gettext("unreserved items will be returned to the general list:")}
      </p>
      <ul style="color: #4b5563; line-height: 1.6;">
        #{Enum.map_join(unreserved_cards, "", fn card -> "<li>#{card.card.title}</li>" end)}
      </ul>
      """
    end}
          <p style="color: #4b5563; line-height: 1.6;">
            #{gettext("Reserved items will be removed from the system.")}
          </p>
        </div>
      </div>

      <div style="text-align: center; margin: 32px 0;">
        <a href="#{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}"
           style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 32px; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.3);">
          #{gettext("View Wishlist")}
        </a>
      </div>

      <div style="text-align: center; border-top: 1px solid #e5e7eb; padding-top: 24px; margin-top: 32px;">
        <p style="color: #6b7280; font-size: 14px;">#{gettext("The Wishlists Team")}</p>
        <p style="color: #6b7280; font-size: 12px; margin-top: 16px;">
          #{gettext("To unsubscribe from cleanup notifications, click the \"Unsubscribe\" link in your email client or visit your notification preferences in your account settings.")}
        </p>
      </div>
    </div>
    """
  end

  defp folder_cleanup_text_body(user, folder, unreserved_cards) do
    celebration_message = get_celebration_message(folder.event_type)

    """
    #{celebration_message.title}

    #{gettext("Hi")} #{user.email},

    #{celebration_message.text} #{celebration_message.emoji}

    #{gettext("As the event has passed, your wishlist")} "#{folder.name}" #{gettext("will be archived soon.")}

    #{if length(unreserved_cards) > 0 do
      """
      #{length(unreserved_cards)} #{gettext("unreserved items will be returned to the general list:")}
      #{Enum.map_join(unreserved_cards, "\n", fn card -> "- #{card.card.title}" end)}
      """
    end}

    #{gettext("Reserved items will be removed from the system.")}

    #{gettext("View your wishlist")}: #{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}

    #{gettext("Best wishes")},
    #{gettext("The Wishlists Team")}

    ---
    #{gettext("To unsubscribe from cleanup notifications, use the \"Unsubscribe\" link in your email client or visit your notification preferences in your account settings.")}
    """
  end

  defp get_celebration_message(event_type) do
    case event_type do
      "birthday" ->
        %{
          title: gettext("Happy Birthday!"),
          text: gettext("We hope you had an amazing birthday celebration!"),
          emoji: "🎉🎈"
        }

      "wedding" ->
        %{
          title: gettext("Congratulations on Your Wedding!"),
          text: gettext("Wishing you a lifetime of love and happiness together!"),
          emoji: "💑💍"
        }

      "christmas" ->
        %{
          title: gettext("Merry Christmas!"),
          text: gettext("We hope your holidays were filled with joy and wonderful presents!"),
          emoji: "🎁⛄"
        }

      "new_year" ->
        %{
          title: gettext("Happy New Year!"),
          text: gettext("Wishing you an amazing year ahead!"),
          emoji: "✨🎆"
        }

      "valentines_day" ->
        %{
          title: gettext("Happy Valentine's Day!"),
          text: gettext("We hope your day was filled with love!"),
          emoji: "💝💘"
        }

      _ ->
        %{
          title: gettext("Congratulations!"),
          text: gettext("We hope you had a wonderful celebration!"),
          emoji: "🎊✨"
        }
    end
  end
end
