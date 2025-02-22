defmodule Wishlists.Email.EmailTemplates do
  import Swoosh.Email

  def welcome_email(user) do
    new()
    |> to({user.email, user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject("Welcome to Wishlists!")
    |> html_body(welcome_html_body(user))
    |> text_body(welcome_text_body(user))
  end

  def reservation_notification(folder, folder_card, reserver_name) do
    new()
    |> to({folder.user.email, folder.user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject("New Reservation in Your Wishlist!")
    |> html_body(reservation_html_body(folder, folder_card, reserver_name))
    |> text_body(reservation_text_body(folder, folder_card, reserver_name))
  end

  def reset_password_email(user) do
    new()
    |> to({user.email, user.email})
    |> from({"Wishlists", "notifications@hochu-hochu.com"})
    |> subject("Reset Your Password")
    |> html_body(reset_password_html_body(user))
    |> text_body(reset_password_text_body(user))
  end

  defp welcome_html_body(user) do
    """
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); padding: 32px;">
      <div style="text-align: center; margin-bottom: 32px;">
        <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; letter-spacing: -0.5px;">
          Welcome to Wishlists!
        </div>
      </div>

      <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 2px; border-radius: 12px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 10px; padding: 24px;">
          <p style="color: #1f2937; font-size: 18px; margin-bottom: 16px;">Hi #{user.email},</p>
          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px;">Thank you for joining Wishlists! We're excited to help you manage your wishes and share them with friends and family.</p>
          <p style="color: #4b5563; line-height: 1.6; font-weight: 500;">Get started by creating your first wishlist!</p>
        </div>
      </div>

      <div style="text-align: center; margin: 32px 0;">
        <a href="#{WishlistsWeb.Endpoint.url()}/dashboard"
           style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 32px; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.3);">
          Go to Dashboard ✨
        </a>
      </div>

      <div style="text-align: center; border-top: 1px solid #e5e7eb; padding-top: 24px; margin-top: 32px;">
        <p style="color: #6b7280; font-size: 16px; margin-bottom: 8px;">Happy wishing! 🌟</p>
        <p style="color: #4f46e5; font-weight: 600; font-size: 14px;">The Wishlists Team</p>
      </div>
    </div>
    """
  end

  defp welcome_text_body(user) do
    """
    ✨ Welcome to Wishlists! ✨

    Hi #{user.email},

    Thank you for joining Wishlists! We're excited to help you manage your wishes and share them with friends and family.

    Get started by creating your first wishlist!

    Visit our Dashboard: #{WishlistsWeb.Endpoint.url()}/dashboard

    Happy wishing! 🌟

    Best wishes,
    The Wishlists Team
    """
  end

  defp reservation_html_body(folder, folder_card, reserver_name) do
    """
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h1 style="color: #4f46e5;">New Reservation!</h1>
      <p>Hi #{folder.user.email},</p>
      <p>Great news! Someone has reserved an item from your wishlist "#{folder.name}".</p>
      <div style="background-color: #f3f4f6; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <p style="margin: 0;"><strong>Item:</strong> #{folder_card.card.title}</p>
        <p style="margin: 10px 0;"><strong>Reserved by:</strong> #{reserver_name}</p>
      </div>
      <div style="margin: 30px 0;">
        <a href="#{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}"
           style="background-color: #4f46e5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px;">
          View Wishlist
        </a>
      </div>
      <p>Best wishes,</p>
      <p>The Wishlists Team</p>
    </div>
    """
  end

  defp reservation_text_body(folder, folder_card, reserver_name) do
    """
    New Reservation!

    Hi #{folder.user.email},

    Great news! Someone has reserved an item from your wishlist "#{folder.name}".

    Item: #{folder_card.card.title}
    Reserved by: #{reserver_name}

    View your wishlist: #{WishlistsWeb.Endpoint.url()}/folders/#{folder.id}

    Best wishes,
    The Wishlists Team
    """
  end

  defp reset_password_html_body(user) do
    reset_url = "#{WishlistsWeb.Endpoint.url()}/reset-password/#{user.reset_password_token}"

    """
    <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); padding: 32px;">
      <div style="text-align: center; margin-bottom: 32px;">
        <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; font-size: 32px; font-weight: 800; letter-spacing: -0.5px;">
          Reset Your Password
        </div>
      </div>

      <div style="background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); padding: 2px; border-radius: 12px; margin-bottom: 32px;">
        <div style="background: white; border-radius: 10px; padding: 24px;">
          <p style="color: #1f2937; font-size: 18px; margin-bottom: 16px;">Hi #{user.email},</p>
          <p style="color: #4b5563; line-height: 1.6; margin-bottom: 16px;">You requested to reset your password. Click the button below to set a new password.</p>
          <p style="color: #4b5563; line-height: 1.6; font-weight: 500;">This link will expire in 24 hours.</p>
        </div>
      </div>

      <div style="text-align: center; margin: 32px 0;">
        <a href="#{reset_url}"
           style="display: inline-block; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 16px 32px; text-decoration: none; border-radius: 50px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 6px rgba(79, 70, 229, 0.3);">
          Reset Password 🔐
        </a>
      </div>

      <div style="text-align: center; border-top: 1px solid #e5e7eb; padding-top: 24px; margin-top: 32px;">
        <p style="color: #6b7280; font-size: 16px; margin-bottom: 8px;">If you didn't request this, please ignore this email.</p>
        <p style="color: #4f46e5; font-weight: 600; font-size: 14px;">The Wishlists Team</p>
      </div>
    </div>
    """
  end

  defp reset_password_text_body(user) do
    reset_url = "#{WishlistsWeb.Endpoint.url()}/reset-password/#{user.reset_password_token}"

    """
    🔐 Reset Your Password

    Hi #{user.email},

    You requested to reset your password. Visit the following link to set a new password:

    #{reset_url}

    This link will expire in 24 hours.

    If you didn't request this, please ignore this email.

    Best wishes,
    The Wishlists Team
    """
  end
end
