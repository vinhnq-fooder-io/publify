# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SettingsController, type: :controller do
  render_views

  let!(:blog) { create(:blog) }

  before do
    alice = create(:user, :as_admin, login: "alice")
    sign_in alice
  end

  describe "#index" do
    before { get :index }

    it { expect(response).to render_template("index") }
  end

  describe "#write" do
    before { get :write }

    it { expect(response).to render_template("write") }
  end

  describe "#display" do
    before { get :display }

    it { expect(response).to render_template("display") }
  end

  describe "#feedback" do
    before { get :feedback }

    it { expect(response).to render_template("feedback") }
  end

  describe "#update" do
    it "updates the settings" do
      post :update, params: { setting: { blog_name: "New name" } }
      expect(blog.reload.blog_name).to eq "New name"
    end

    it "redirects to :index by default" do
      post :update, params: { setting: { blog_name: "New name" } }
      expect(response).to redirect_to(admin_settings_path)
    end

    context "when updating the language" do
      it "sets the flash in the new language" do
        I18n.with_locale :en do
          post :update, params: { setting: { lang: "nl" } }
          expect(flash[:success]).to eq I18n.t("admin.settings.update.success", locale: :nl)
        end
      end
    end
  end
end
