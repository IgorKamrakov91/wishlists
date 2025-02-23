defmodule WishlistsWeb.SitemapController do
  use WishlistsWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header("content-disposition", "inline")
    |> halt_if_already_sent()
    |> send_resp(:ok, generate_sitemap())
  end

  defp generate_sitemap do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <?xml-stylesheet type="text/xsl" href="/sitemap.xsl"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
            xmlns:xhtml="http://www.w3.org/1999/xhtml">
        <url>
            <loc>https://hochu-hochu.com</loc>
            <lastmod>#{Date.utc_today()}</lastmod>
            <xhtml:link rel="alternate" hreflang="en" href="https://hochu-hochu.com/?locale=en"/>
            <xhtml:link rel="alternate" hreflang="ru" href="https://hochu-hochu.com/?locale=ru"/>
            <changefreq>weekly</changefreq>
            <priority>1.0</priority>
        </url>
        <url>
            <loc>https://hochu-hochu.com/dashboard</loc>
            <lastmod>#{Date.utc_today()}</lastmod>
            <xhtml:link rel="alternate" hreflang="en" href="https://hochu-hochu.com/dashboard?locale=en"/>
            <xhtml:link rel="alternate" hreflang="ru" href="https://hochu-hochu.com/dashboard?locale=ru"/>
            <changefreq>daily</changefreq>
            <priority>0.8</priority>
        </url>
        <url>
            <loc>https://hochu-hochu.com/forgot-password</loc>
            <lastmod>#{Date.utc_today()}</lastmod>
            <xhtml:link rel="alternate" hreflang="en" href="https://hochu-hochu.com/forgot-password?locale=en"/>
            <xhtml:link rel="alternate" hreflang="ru" href="https://hochu-hochu.com/forgot-password?locale=ru"/>
            <changefreq>monthly</changefreq>
            <priority>0.5</priority>
        </url>
        <url>
            <loc>https://hochu-hochu.com/?locale=en</loc>
            <lastmod>#{Date.utc_today()}</lastmod>
            <xhtml:link rel="alternate" hreflang="ru" href="https://hochu-hochu.com/?locale=ru"/>
            <xhtml:link rel="alternate" hreflang="en" href="https://hochu-hochu.com/?locale=en"/>
            <changefreq>weekly</changefreq>
            <priority>0.9</priority>
        </url>
        <url>
            <loc>https://hochu-hochu.com/?locale=ru</loc>
            <lastmod>#{Date.utc_today()}</lastmod>
            <xhtml:link rel="alternate" hreflang="en" href="https://hochu-hochu.com/?locale=en"/>
            <xhtml:link rel="alternate" hreflang="ru" href="https://hochu-hochu.com/?locale=ru"/>
            <changefreq>weekly</changefreq>
            <priority>0.9</priority>
        </url>
    </urlset>
    """
  end

  defp halt_if_already_sent(%Plug.Conn{state: :sent} = conn), do: conn
  defp halt_if_already_sent(conn), do: conn
end
