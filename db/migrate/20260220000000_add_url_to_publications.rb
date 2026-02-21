class AddUrlToPublications < ActiveRecord::Migration[7.1]
  def change
    add_column :publications, :url, :string
  end
end
