class GeographicLocation < ApplicationRecord
  has_many :publications
  
  validates :name, presence: true, uniqueness: { case_sensitive: false}

  geocoded_by :name, latitude: :latitude, longitude: :longitude
  after_validation :geocode, if: -> { will_save_change_to_name? }
end
