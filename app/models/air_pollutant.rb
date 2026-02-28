class AirPollutant < ApplicationRecord
  include PgSearch::Model

  pg_search_scope :search_by_term,
                  against: :name,
                  using: {
                    tsearch: { prefix: true, any_word: true },
                    trigram: {}
                  }
  has_and_belongs_to_many :publications, join_table: 'pub_air_pollutants'

  validates :name, presence: true, uniqueness: { case_sensitive: false}
end
