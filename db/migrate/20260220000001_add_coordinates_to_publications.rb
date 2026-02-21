class AddCoordinatesToPublications < ActiveRecord::Migration[7.1]
  def change
    add_column :publications, :latitude, :decimal, precision: 10, scale: 6
    add_column :publications, :longitude, :decimal, precision: 10, scale: 6
  end
end
