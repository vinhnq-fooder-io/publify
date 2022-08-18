# frozen_string_literal: true

require "rails_helper"

RSpec.describe "authors/show_rss_feed.rss.builder", type: :view do
  let!(:blog) { create(:blog) }

  describe "rendering articles (with some funny characters)" do
    before do
      article1 = create :full_article, published_at: 1.minute.ago
      article1.body = "&eacute;coute!"
      article2 = create :full_article, published_at: 2.minutes.ago
      article2.body = "is 4 < 2? no!"
      assign(:articles, [article1, article2])
      render
    end

    it "create a valid RSS feed with two items" do
      assert_rss20 rendered, 2
    end

    it "renders the article RSS partial twice" do
      expect(view).to render_template(partial: "shared/_rss_item_article", count: 2)
    end
  end
end
