# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SeoController, type: :controller do
  let!(:blog) { create(:blog) }
  let(:admin) { create(:user, :as_admin) }

  before do
    sign_in admin
  end

  describe "#show" do
    render_views

    context "with no section" do
      before { get :show }

      it "renders the general section" do
        expect(response).to render_template("_general")
      end
    end

    context "with section permalinks" do
      before { get :show, params: { section: :permalinks } }

      it "renders the permalinks section" do
        expect(response).to render_template("_permalinks")
      end
    end

    context "with section titles" do
      before { get :show, params: { section: :titles } }

      it "renders the titled section" do
        expect(response).to render_template("_titles")
      end
    end
  end

  describe "update" do
    before do
      put :update, params: { section: "permalinks", setting: { permalink_format: format } }
    end

    context "simple title format" do
      let(:format) { "/%title%" }

      it { expect(response).to redirect_to admin_seo_path(section: "permalinks") }
      it { expect(blog.reload.permalink_format).to eq(format) }
      it { expect(flash[:success]).to eq(I18n.t("admin.settings.update.success")) }
    end

    context "without title format" do
      let(:format) { "/%month%" }

      it { expect(blog.reload.permalink_format).not_to eq(format) }

      it {
        expect(flash[:error]).
          to eq(I18n.t("admin.settings.update.error",
                       messages: I18n.t("errors.permalink_need_a_title")))
      }
    end
  end

  describe "update action" do
    def good_update(options = {})
      robots =
        "User-agent: *\r\nDisallow: /admin/\r\nDisallow: /page/\r\n" \
        "Disallow: /cgi-bin \r\nUser-agent: Googlebot-Image\r\nAllow: /*"
      put :update, params: { "section" => "general",
                             "setting" => { "permalink_format" => "/%title%.html",
                                            "unindex_categories" => "1",
                                            "google_analytics" => "",
                                            "meta_keywords" => "my keywords",
                                            "meta_description" => "",
                                            "rss_description" => "1",
                                            "robots" => robots,
                                            "index_tags" => "1" } }.merge(options)
    end

    it "successes" do
      good_update
      expect(response).to redirect_to admin_seo_path(section: "general")
    end

    it "does not save blog with bad permalink format" do
      @blog = Blog.first
      good_update "setting" => { "permalink_format" => "/%month%" }
      expect(response).to render_template("show")
      expect(@blog).to eq(Blog.first)
    end
  end
end
