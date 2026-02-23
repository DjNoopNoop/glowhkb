class Publication < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :geographic_location, optional: true

  validates :title, presence: true
  
  has_and_belongs_to_many :air_pollutants
  has_and_belongs_to_many :weather_parameters
  has_and_belongs_to_many :medical_conditions
  has_and_belongs_to_many :statistical_methods
end
