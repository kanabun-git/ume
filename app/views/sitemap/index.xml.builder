xml.instruct! :xml, version: "1.0"
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
  end
  xml.url do
    xml.loc shops_url
    xml.changefreq "daily"
  end
  xml.url do
    xml.loc rankings_url
    xml.changefreq "daily"
  end

  @areas.each do |area|
    xml.url do
      xml.loc area_url(area)
      xml.changefreq "weekly"
    end
  end

  @genres.each do |genre|
    xml.url do
      xml.loc genre_url(genre)
      xml.changefreq "weekly"
    end
  end

  @shops.each do |shop|
    xml.url do
      xml.loc shop_url(shop)
      xml.lastmod shop.updated_at.iso8601
      xml.changefreq "daily"
    end
  end

  @casts.each do |cast|
    xml.url do
      xml.loc cast_url(cast)
      xml.lastmod cast.updated_at.iso8601
      xml.changefreq "daily"
    end
  end
end
