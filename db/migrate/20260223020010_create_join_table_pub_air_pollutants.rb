class CreateJoinTablePubAirPollutants < ActiveRecord::Migration[7.1]
  def change
    create_table :pub_air_pollutants, id: false do |t|
      t.bigint :publication_id, null: false
      t.bigint :air_pollutant_id, null: false
    end
    add_index :pub_air_pollutants, [:publication_id, :air_pollutant_id], name: 'idx_pub_ap'
    add_index :pub_air_pollutants, [:air_pollutant_id, :publication_id], name: 'idx_ap_pub'
  end
end
