class AddGeographicLocationToPublications < ActiveRecord::Migration[7.1]
  def change
    add_reference :publications, :geographic_location, null: true, foreign_key: true
  end
end
