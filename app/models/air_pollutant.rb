class AirPollutant < ApplicationRecord
  has_and_belongs_to_many :publications, join_table: 'pub_air_pollutants'
end
