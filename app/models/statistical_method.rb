class StatisticalMethod < ApplicationRecord
  has_and_belongs_to_many :publications, join_table: 'pub_statistical_methods'

  validates :name, presence: true, uniqueness: { case_sensitive: false}
end
