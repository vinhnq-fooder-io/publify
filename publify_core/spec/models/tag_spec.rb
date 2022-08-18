# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  let!(:blog) { create(:blog) }

  it "tags are unique" do
    expect { blog.tags.create!(name: "test") }.not_to raise_error
    test_tag = blog.tags.new(name: "test")
    expect(test_tag).not_to be_valid
    expect(test_tag.errors[:name]).to eq(["has already been taken"])
  end

  describe "validations" do
    let(:tag) { described_class.new }

    it "requires name to be present" do
      expect(tag).to validate_presence_of(:name)
    end

    it "requires display_name to not be too long" do
      expect(tag).to validate_length_of(:display_name).is_at_most(255)
    end
  end

  it "display names with spaces can be found by dash joined name" do
    tag = blog.tags.create(name: "Monty Python")
    expect(tag).to be_valid
    expect(tag.name).to eq("monty-python")
    expect(tag.display_name).to eq("Monty Python")
  end

  it "display names with colon can be found by dash joined name" do
    tag = blog.tags.create(name: "SaintSeya:Hades")
    expect(tag).to be_valid
    expect(tag.name).to eq("saintseya-hades")
    expect(tag.display_name).to eq("SaintSeya:Hades")
  end

  it "articles can be tagged" do
    a = Article.create(title: "an article", blog: blog)
    foo = create(:tag, name: "foo")
    bar = create(:tag, name: "bar")
    a.tags << foo
    a.tags << bar
    a.reload
    expect(a.tags.size).to eq(2)
    expect(a.tags.sort_by(&:id)).to eq([foo, bar].sort_by(&:id))
  end

  it "find_all_with_content_counters finds 2 tags" do
    a = create(:article, title: "an article a")
    b = create(:article, title: "an article b")
    c = create(:article, title: "an article c")
    create(:tag, name: "foo", contents: [a, b, c])
    create(:tag, name: "bar", contents: [a, b])
    tags = described_class.find_all_with_content_counters
    expect(tags.entries.size).to eq(2)
    expect(tags.first.name).to eq("foo")
    expect(tags.first.content_counter).to eq(3)
    expect(tags.last.name).to eq("bar")
    expect(tags.last.content_counter).to eq(2)
    expect(tags.first.blog).to eq blog
  end

  describe "permalink_url" do
    let(:tag) { build(:tag, blog: blog, name: "foo", display_name: "Foo") }

    it "returns a full url based on the tag name in the tag section" do
      expect(tag.permalink_url).to eq("#{blog.base_url}/tag/foo")
    end
  end

  describe "#published_articles" do
    it "returns only published articles" do
      published_art = create(:article)
      draft_art = create(:article, published_at: nil, state: "draft")
      art_tag = create(:tag, name: "art", contents: [published_art, draft_art])
      expect(art_tag.published_contents.size).to eq(1)
    end
  end

  context "with tags foo, bar and bazz" do
    before do
      @foo = create(:tag, name: "foo")
      @bar = create(:tag, name: "bar")
      @bazz = create(:tag, name: "bazz")
    end

    it "find_with_char('f') should be return foo" do
      expect(described_class.find_with_char("f")).to eq([@foo])
    end

    it "find_with_char('v') should return empty data" do
      expect(described_class.find_with_char("v")).to eq([])
    end

    it "find_with_char('ba') should return tag bar and bazz" do
      expect(described_class.find_with_char("ba").sort_by(&:id)).
        to eq([@bar, @bazz].sort_by(&:id))
    end

    describe "#create_from_article" do
      before { described_class.create_from_article!(article) }

      context "without keywords" do
        let(:article) { create(:article, keywords: nil) }

        it { expect(article.tags).to be_empty }
      end

      context "with a simple keyword" do
        let(:article) { create(:article, keywords: "foo") }

        it { expect(article.tags.size).to eq(1) }
        it { expect(article.tags.first).to be_kind_of(described_class) }
        it { expect(article.tags.first.name).to eq("foo") }
      end

      context "with a simple keyword, but containing a semi-colon" do
        let(:article) { create(:article, keywords: "lang:fr") }

        it { expect(article.tags.size).to eq(1) }
        it { expect(article.tags.first).to be_kind_of(described_class) }
        it { expect(article.tags.first.name).to eq("lang-fr") }
      end

      context "with two keyword separate by a coma" do
        let(:article) { create(:article, keywords: "foo, bar") }

        it { expect(article.tags.size).to eq(2) }
        it { expect(article.tags.map(&:name)).to eq(%w(foo bar)) }
      end

      context "with two keyword with apostrophe" do
        let(:article) { create(:article, keywords: "foo, l'bar") }

        it { expect(article.tags.size).to eq(3) }
        it { expect(article.tags.map(&:name)).to eq(%w(foo l bar)) }
      end

      context "with two identical keywords" do
        let(:article) { create(:article, keywords: "same'same") }

        it { expect(article.tags.size).to eq(1) }
        it { expect(article.tags.map(&:name)).to eq(["same"]) }
      end
    end
  end
end
