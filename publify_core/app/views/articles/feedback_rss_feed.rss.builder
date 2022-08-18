# frozen_string_literal: true

xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.instruct! "xml-stylesheet", type: "text/css", href: url_for("/stylesheets/rss.css")

xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
        "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title feed_title
    xml.link @article.permalink_url
    xml.atom :link, href: request.url, rel: "self", type: "application/rss+xml"
    xml.language this_blog.lang.tr("_", "-").downcase
    xml.ttl "40"
    xml.description this_blog.blog_subtitle

    feedback = @article.published_feedback
    feedback.each do |item|
      render "shared/rss_item_#{item.type.downcase}", feed: xml, item: item
    end
  end
end
