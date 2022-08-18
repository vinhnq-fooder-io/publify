# frozen_string_literal: true

require "rails_helper"

RSpec.describe String do
  describe "#to_permalink" do
    it "builds a nice permalink from an accentuated string" do
      expect("L'été s'ra chaud, l'été s'ra chaud".to_permalink).
        to eq("l-ete-s-ra-chaud-l-ete-s-ra-chaud")
    end
  end

  describe "to_url" do
    it "gives a proper space-less, trimmed URL" do
      expect(" this is  a sentence ".to_url).to eq("this-is-a-sentence")
    end
  end

  describe "strip_html" do
    it "renders text only" do
      expect("<a href='http://myblog.com'>my blog</a>".strip_html).to eq("my blog")
    end

    it "does not remove a > from a numeric comparison" do
      expect("5 < 6 > 4".strip_html).to eq("5 < 6 > 4")
    end
  end
end
