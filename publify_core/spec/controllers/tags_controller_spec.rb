# frozen_string_literal: true

require "rails_helper"

RSpec.describe TagsController, type: :controller do
  describe "#index" do
    before do
      create(:blog)
      @tag = create(:tag)
      @tag.contents << create(:article)
    end

    describe "normally" do
      before do
        get "index"
      end

      specify { expect(response).to be_successful }
      specify { expect(response).to render_template("tags/index") }
      specify { expect(assigns(:tags)).to match_array([@tag]) }
    end
  end

  describe "showing a single tag" do
    before do
      create(:blog)
      @tag = create(:tag, name: "Foo")
    end

    def do_get
      get "show", params: { id: "foo" }
    end

    describe "with some articles" do
      before do
        @articles = create_list :article, 2
        @tag.contents << @articles
      end

      it "is successful" do
        do_get
        expect(response).to be_successful
      end

      it "retrieves the correct set of articles" do
        do_get
        expect(assigns[:articles].map(&:id).sort).to eq(@articles.map(&:id).sort)
      end

      it "renders :show by default" do
        do_get
        expect(response).to render_template(:show)
      end

      it "renders the tag template if present" do
        # NOTE: Stubbing Object under test :-(.
        allow(controller).to receive(:template_exists?).and_return(true)
        allow(controller).to receive(:render)
        do_get
        expect(controller).to have_received(:render).with("foo")
      end

      it "assigns the correct page title" do
        do_get
        expect(assigns[:page_title]).to eq "Tag: foo | test blog"
      end

      it "assigns the correct description" do
        do_get
        expect(assigns(:description)).to eq "foo | test blog | test subtitle"
      end

      it "renders the atom feed for /articles/tag/foo.atom" do
        get "show", params: { id: "foo", format: "atom" }
        expect(response).to render_template("articles/index_atom_feed", layout: false)
      end

      it "renders the rss feed for /articles/tag/foo.rss" do
        get "show", params: { id: "foo", format: "rss" }
        expect(response).to render_template("articles/index_rss_feed", layout: false)
      end
    end

    describe "without articles" do
      it "raises RecordNotFound" do
        expect { get "show", params: { id: "foo" } }.
          to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe "showing a non-existant tag" do
    it "signals not found" do
      create(:blog)
      expect { get "show", params: { id: "thistagdoesnotexist" } }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "SEO Options" do
    before do
      @blog = create(:blog)
      @a = create(:article)
      @foo = create(:tag, name: "foo", contents: [@a])
    end

    describe "keywords" do
      it "does not assign keywords when the blog has no keywords" do
        get "show", params: { id: "foo" }

        expect(assigns(:keywords)).to eq ""
      end

      it "assigns the blog's keywords if present" do
        @blog.meta_keywords = "foo, bar"
        @blog.save
        get "show", params: { id: "foo" }
        expect(assigns(:keywords)).to eq "foo, bar"
      end
    end
  end
end
