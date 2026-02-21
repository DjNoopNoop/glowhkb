class Publication < ApplicationRecord
  belongs_to :user, optional: true

  validates :title, presence: true
  
  geocoded_by :country_region, latitude: :latitude, longitude: :longitude
  after_validation :geocode, if: -> { will_save_change_to_country_region? }
end
