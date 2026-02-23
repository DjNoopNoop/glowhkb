class CreatePublications < ActiveRecord::Migration[7.1]
  def change
    create_table :publications do |t|
      t.string  :title, null: false
      t.text    :authors
      t.string  :journal
      t.integer :year
      t.string :doi
      t.string :url
      t.timestamps
    end
  end
end
