# frozen_string_literal: true

module XmlHelper
  def collection_lastmod(collection)
    article_updated = collection.contents.order(updated_at: :desc).first
    article_published = collection.contents.order(published_at: :desc).first

    times = []
    times.push article_updated.updated_at if article_updated
    times.push article_published.updated_at if article_published

    if times.empty?
      Time.zone.at(0).xmlschema
    else
      times.max.xmlschema
    end
  end
end
