class WeatherParameter < ApplicationRecord
  has_and_belongs_to_many :publications, join_table: 'pub_weather_parameters'

  validates :name, presence: true, uniqueness: { case_sensitive: false}
end
