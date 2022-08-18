# frozen_string_literal: true

class AddTextFilterNameFields < ActiveRecord::Migration[5.2]
  def change
    add_column :contents, :text_filter_name, :string
    add_column :feedback, :text_filter_name, :string
    add_column :users, :text_filter_name, :string
  end
end
