class CreateJoinTablesForSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :sub_air_pollutants, id: false do |t|
      t.bigint :submission_id, null: false
      t.bigint :air_pollutant_id, null: false
    end
    add_index :sub_air_pollutants, [:submission_id, :air_pollutant_id], name: 'idx_sub_ap'
    add_index :sub_air_pollutants, [:air_pollutant_id, :submission_id], name: 'idx_ap_sub'

    create_table :sub_weather_parameters, id: false do |t|
      t.bigint :submission_id, null: false
      t.bigint :weather_parameter_id, null: false
    end
    add_index :sub_weather_parameters, [:submission_id, :weather_parameter_id], name: 'idx_sub_wp'
    add_index :sub_weather_parameters, [:weather_parameter_id, :submission_id], name: 'idx_wp_sub'

    create_table :sub_medical_conditions, id: false do |t|
      t.bigint :submission_id, null: false
      t.bigint :medical_condition_id, null: false
    end
    add_index :sub_medical_conditions, [:submission_id, :medical_condition_id], name: 'idx_sub_mc'
    add_index :sub_medical_conditions, [:medical_condition_id, :submission_id], name: 'idx_mc_sub'

    create_table :sub_statistical_methods, id: false do |t|
      t.bigint :submission_id, null: false
      t.bigint :statistical_method_id, null: false
    end
    add_index :sub_statistical_methods, [:submission_id, :statistical_method_id], name: 'idx_sub_sm'
    add_index :sub_statistical_methods, [:statistical_method_id, :submission_id], name: 'idx_sm_sub'
  end
end
