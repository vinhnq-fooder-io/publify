# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthorsController, type: :controller do
  let!(:blog) { create(:blog, limit_article_display: 1) }
  let(:now) { DateTime.new(2012, 12, 23, 3, 45).in_time_zone }

  describe "#show" do
    context "with an empty profile" do
      let(:no_profile_user) { create(:user) }
      let!(:article) { create(:article, user: no_profile_user, published_at: now - 1.hour) }

      describe "html" do
        before { get "show", params: { id: no_profile_user.login } }

        it { expect(response).to render_template(:show) }
        it { expect(assigns(:author)).to eq(no_profile_user) }
        it { expect(assigns(:articles)).to eq([article]) }
      end

      describe "atom feed" do
        before { get "show", params: { id: no_profile_user.login, format: "atom" } }

        it { expect(response).to render_template(:show_atom_feed, false) }
      end

      describe "rss feed" do
        before { get "show", params: { id: no_profile_user.login, format: "rss" } }

        it { expect(response).to render_template(:show_rss_feed, false) }
      end

      describe "with pagination" do
        let!(:article_page_2) do
          create(:article, user: no_profile_user,
                           published_at: now - 1.day)
        end

        before { get "show", params: { id: no_profile_user.login, page: 2 } }

        it { expect(assigns(:articles)).to eq([article_page_2]) }
      end
    end

    context "with a full profile" do
      let!(:full_profile_user) { create(:user, :with_a_full_profile) }
      let!(:article) { create(:article, user: full_profile_user) }

      describe "html" do
        before { get "show", params: { id: full_profile_user.login } }

        it { expect(response).to render_template(:show) }
        it { expect(assigns(:author)).to eq(full_profile_user) }
        it { expect(assigns(:articles)).to eq([article]) }
      end
    end
  end
end
