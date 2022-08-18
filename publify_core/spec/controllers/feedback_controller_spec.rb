# frozen_string_literal: true

require "rails_helper"

RSpec.describe FeedbackController, type: :controller do
  describe "index" do
    let!(:items) do
      [
        create(:comment, state: :presumed_ham),
        create(:comment),
        create(:trackback, title: "some"),
        create(:trackback, title: "items"),
      ]
    end

    let!(:spammy_items) do
      [
        create(:spam_comment),
        create(:trackback, state: "spam"),
      ]
    end

    context "with atom format" do
      before { get "index", params: { format: "atom" } }

      it "responds with success" do
        expect(response).to be_successful
      end

      it "assigns feedback in the reverse chronological order" do
        expect(assigns(:feedback)).to eq items.reverse
      end

      it "renders the index template" do
        expect(response).to render_template("feedback/index")
      end
    end

    context "with rss format" do
      before { get "index", params: { format: "rss" } }

      it "responds with success" do
        expect(response).to be_successful
      end

      it "assigns all feedback" do
        expect(assigns(:feedback)).to match_array items
      end

      it "renders the index template" do
        expect(response).to render_template("feedback/index")
      end
    end
  end
end
