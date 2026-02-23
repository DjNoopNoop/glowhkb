class WeatherParameter < ApplicationRecord
  has_and_belongs_to_many :publications
end
