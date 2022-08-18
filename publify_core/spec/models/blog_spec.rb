# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blog, type: :model do
  describe "#initialize" do
    it "accepts a settings field in its parameter hash" do
      described_class.new("blog_name" => "foo")
    end
  end

  describe "A blog" do
    before do
      @blog = described_class.new
    end

    it "values boolify like Perl" do
      { "0 but true" => true, "" => false, "false" => false, 1 => true, 0 => false,
        nil => false, "f" => false }.each do |value, expected|
        @blog.sp_global = value
        expect(@blog.sp_global).to eq(expected)
      end
    end

    ["", "/sub-uri"].each do |sub_url|
      describe "when running in with http://myblog.net#{sub_url}" do
        before do
          @base_url = "http://myblog.net#{sub_url}"
          @blog.base_url = @base_url
        end

        [true, false].each do |only_path|
          describe "blog.url_for" do
            describe "with a hash argument and only_path = #{only_path}" do
              subject do
                @blog.url_for(controller: "tags", action: "show", id: 1,
                              only_path: only_path)
              end

              it { is_expected.to eq("#{only_path ? sub_url : @base_url}/tag/1") }
            end

            describe "with a string argument and only_path = #{only_path}" do
              subject { @blog.url_for("tag/1", only_path: only_path) }

              it { is_expected.to eq("#{only_path ? sub_url : @base_url}/tag/1") }
            end
          end
        end
      end
    end
  end

  describe "The first blog" do
    before do
      @blog = create :blog
    end

    it "allows another blog to be created" do
      expect(described_class.new(base_url: "bar")).to be_valid
    end
  end

  describe "Given no blogs, a new default blog" do
    before do
      @blog = described_class.new(base_url: "foo")
    end

    it "is valid after filling the title" do
      @blog.blog_name = "something not empty"
      expect(@blog).to be_valid
    end

    it "is valid without filling the title" do
      expect(@blog.blog_name).to eq("My Shiny Weblog!")
      expect(@blog).to be_valid
    end

    it "is not valid after setting an empty title" do
      @blog.blog_name = ""
      expect(@blog).not_to be_valid
    end
  end

  describe "Valid permalink in blog" do
    before do
      @blog = described_class.new(base_url: "foo")
    end

    ["foo", "year", "day", "month", "title", "%title", "title%",
     "/year/month/day/title", "%year%", "%day%", "%month%",
     "%title%.html.atom", "%title%.html.rss"].each do |permalink_type|
      it "not valid with #{permalink_type}" do
        @blog.permalink_format = permalink_type
        expect(@blog).not_to be_valid
      end
    end

    ["%title%", "%title%.html", "/hello/all/%year%/%title%",
     "atom/%title%.html", "ok/rss/%title%.html"].each do |permalink_type|
      it "is valid with only #{permalink_type}" do
        @blog.permalink_format = permalink_type
        expect(@blog).to be_valid
      end
    end

    it "is not valid without %title% in" do
      @blog.permalink_format = "/toto/%year%/%month/%day%"
      expect(@blog).not_to be_valid
    end
  end

  describe "validations" do
    let(:blog) { described_class.new }

    it "requires base url to not be too long" do
      expect(blog).to validate_length_of(:base_url).is_at_most(255)
    end

    it "requires blog name to not be too long" do
      expect(blog).to validate_length_of(:blog_name).is_at_most(256)
    end

    it "allows up to 2048 characters for the rss_description_text setting" do
      expect(blog).to validate_length_of(:rss_description_text).is_at_most(2048)
    end

    it "allows up to 2048 characters for the robots setting" do
      expect(blog).to validate_length_of(:robots).is_at_most(2048)
    end

    it "allows up to 2048 characters for the humans setting" do
      expect(blog).to validate_length_of(:humans).is_at_most(2048)
    end

    it "allows up to 2048 characters for the meta_description setting" do
      expect(blog).to validate_length_of(:meta_description).is_at_most(2048)
    end
  end

  describe ".meta_keywords" do
    it "return empty string when nothing" do
      blog = described_class.new
      expect(blog.meta_keywords).to eq ""
    end

    it "return meta keywords when exist" do
      blog = described_class.new(meta_keywords: "key")
      expect(blog.meta_keywords).to eq "key"
    end
  end

  describe ".meta_description" do
    it "return empty string when nothing" do
      blog = described_class.new
      expect(blog.meta_description).to eq ""
    end

    it "return meta keywords when exist" do
      blog = described_class.new(meta_description: "key")
      expect(blog.meta_description).to eq "key"
    end
  end

  describe "#has_twitter_configured?" do
    it "is false without :twitter_consumer_key or twitter_consumer_secret" do
      blog = build(:blog)
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with an empty :twitter_consumer_key and no twitter_consumer_secret" do
      blog = build(:blog, twitter_consumer_key: "")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with an empty twitter_consumer_key and an empty twitter_consumer_secret" do
      blog = build(:blog, twitter_consumer_key: "", twitter_consumer_secret: "")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with a twitter_consumer_key and no twitter_consumer_secret" do
      blog = build(:blog, twitter_consumer_key: "12345")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with a twitter_consumer_key and an empty twitter_consumer_secret" do
      blog = build(:blog, twitter_consumer_key: "12345", twitter_consumer_secret: "")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with a twitter_consumer_secret and no twitter_consumer_key" do
      blog = build(:blog, twitter_consumer_secret: "67890")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is false with a twitter_consumer_secret and an empty twitter_consumer_key" do
      blog = build(:blog, twitter_consumer_secret: "67890", twitter_consumer_key: "")
      expect(blog.has_twitter_configured?).to be(false)
    end

    it "is true with a twitter_consumer_key and a twitter_consumer_secret" do
      blog = build(:blog, twitter_consumer_key: "12345", twitter_consumer_secret: "67890")
      expect(blog.has_twitter_configured?).to be(true)
    end
  end

  describe "#per_page" do
    let(:blog) { create(:blog, limit_article_display: 3, limit_rss_display: 4) }

    it { expect(blog.per_page(nil)).to eq(3) }
    it { expect(blog.per_page("html")).to eq(3) }
    it { expect(blog.per_page("rss")).to eq(4) }
    it { expect(blog.per_page("atom")).to eq(4) }
  end

  describe "#allow_signup?" do
    context "with a blog that allow signup" do
      let(:blog) { build(:blog, allow_signup: 1) }

      it { expect(blog).to be_allow_signup }
    end

    context "with a blog that not allow signup" do
      let(:blog) { build(:blog, allow_signup: 0) }

      it { expect(blog).not_to be_allow_signup }
    end
  end

  describe "#humans" do
    context "default value" do
      let(:blog) { create :blog }

      it { expect(blog.humans).not_to be_nil }
    end

    context "non-default value" do
      let(:blog) { create(:blog, humans: "something to say") }

      it { expect(blog.humans).to eq("something to say") }
    end
  end

  describe "#current_theme" do
    it "returns the correct theme object given a valid theme name" do
      blog = described_class.new(theme: "plain")
      expect(blog.current_theme.name).to eq "plain"
    end

    it "returns a blank theme object given an invalid theme name" do
      blog = described_class.new(theme: "not-there")
      expect(blog.current_theme.name).to eq ""
    end
  end
end
