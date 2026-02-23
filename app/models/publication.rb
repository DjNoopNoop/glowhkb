class Publication < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :geographic_location, optional: true

  validates :title, presence: true
  
  has_and_belongs_to_many :air_pollutants, join_table: 'pub_air_pollutants'
  has_and_belongs_to_many :weather_parameters, join_table: 'pub_weather_parameters'
  has_and_belongs_to_many :medical_conditions, join_table: 'pub_medical_conditions'
  has_and_belongs_to_many :statistical_methods, join_table: 'pub_statistical_methods'
end
