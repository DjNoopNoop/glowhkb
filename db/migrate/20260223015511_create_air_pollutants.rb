class CreateAirPollutants < ActiveRecord::Migration[7.1]
  def change
    create_table :air_pollutants do |t|
      t.string  :name, null: false
      t.timestamps
    end
  end
end
