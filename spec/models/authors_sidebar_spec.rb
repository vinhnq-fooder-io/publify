# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthorsSidebar do
  let(:sidebar) { described_class.new }

  it "is included in the list of available sidebars" do
    expect(SidebarRegistry.available_sidebars).to include(described_class)
  end

  describe "#authors" do
    let!(:authors) { create_list :user, 2 }

    it "returns a list of users" do
      expect(sidebar.authors).to match_array authors
    end
  end
end
