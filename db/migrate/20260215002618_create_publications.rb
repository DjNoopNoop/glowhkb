class CreatePublications < ActiveRecord::Migration[7.1]
  def change
    create_table :publications do |t|
      # Core citation
      t.string  :title, null: false
      t.text    :authors
      t.text    :institutions
      t.string  :journal
      t.integer :year
      t.string  :volume
      t.string  :pages
      t.string :url
      t.string :doi

      # Study details
      t.text    :data_source
      t.text    :population
      t.string  :time_frame
      t.text    :diagnosis
      t.string  :emergency_departments
      t.text    :exposure_periods
      t.string  :country_region
      t.string  :subject_type
      t.string  :disease_studied

      # Demographics + methods
      t.text    :demographics
      t.text    :race_ethnicity
      t.text    :statistical_method

      # Exposures + outcomes
      t.text    :pollution_parameters
      t.text    :weather_parameters
      t.string  :odds_ratio
      t.string  :risk_ratio

      # Geographic coordinates
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      t.timestamps
    end

    add_index :publications, :year
    add_index :publications, :journal
    add_index :publications, :country_region
    add_index :publications, :disease_studied
  end
end
