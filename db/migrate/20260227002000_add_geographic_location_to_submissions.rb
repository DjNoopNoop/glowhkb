class AddGeographicLocationToSubmissions < ActiveRecord::Migration[7.1]
  def change
    add_column :submissions, :geographic_location_id, :bigint
    add_index :submissions, :geographic_location_id, name: 'index_submissions_on_geographic_location_id'
    add_foreign_key :submissions, :geographic_locations
  end
end
