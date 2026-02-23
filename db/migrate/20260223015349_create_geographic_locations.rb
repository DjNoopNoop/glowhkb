class CreateGeographicLocations < ActiveRecord::Migration[7.1]
  def change
    create_table :geographic_locations do |t|
      t.string  :name, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.timestamps
    end
  end
end
