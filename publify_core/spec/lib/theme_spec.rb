# frozen_string_literal: true

require "rails_helper"

RSpec.describe Theme, type: :model do
  let(:blog) { build_stubbed :blog }
  let(:default_theme) { blog.current_theme }

  describe "#layout" do
    it 'returns "layouts/default" by default' do
      theme = described_class.new("test", "test")
      expect(theme.layout("index")).to eq "layouts/default"
    end

    # FIXME: Test pages layout
  end

  describe "#name" do
    it "returns the theme's name (default: plain)" do
      expect(default_theme.name).to eq "plain"
    end
  end

  describe "#description" do
    it "returns the contents of the corresponding markdown file" do
      markdown_file = PublifyCore::Engine.instance.root.join("themes/plain/about.markdown")
      expect(default_theme.description).to eq File.read(markdown_file)
    end
  end

  describe ".find_all" do
    let(:theme_directories) do
      Dir.glob(PublifyCore::Engine.instance.root.join("themes/[a-zA-Z0-9]*")).
        select { |dir| File.readable? "#{dir}/about.markdown" }
    end

    it "finds all the installed themes" do
      expect(described_class.find_all.size).to eq theme_directories.size
    end

    it "includes the default theme" do
      expect(described_class.find_all.map(&:name)).to include "plain"
    end
  end
end
