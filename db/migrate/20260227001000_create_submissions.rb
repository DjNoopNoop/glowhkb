class CreateSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :submissions do |t|
      t.string  :title, null: false
      t.text    :authors
      t.string  :journal
      t.integer :year
      t.string  :doi
      t.string  :url

      t.references :user, null: true, foreign_key: true
      t.bigint :adjudicated_by_id, null: true
      t.datetime :adjudicated_at
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end

    add_foreign_key :submissions, :users, column: :adjudicated_by_id
  end
end
