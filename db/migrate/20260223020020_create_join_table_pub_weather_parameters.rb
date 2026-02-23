class CreateJoinTablePubWeatherParameters < ActiveRecord::Migration[7.1]
  def change
    create_table :pub_weather_parameters, id: false do |t|
      t.bigint :publication_id, null: false
      t.bigint :weather_parameter_id, null: false
    end
    add_index :pub_weather_parameters, [:publication_id, :weather_parameter_id], name: 'idx_pub_wp'
    add_index :pub_weather_parameters, [:weather_parameter_id, :publication_id], name: 'idx_wp_pub'
  end
end
