class StatisticalMethod < ApplicationRecord
  has_and_belongs_to_many :publications, join_table: 'pub_statistical_methods'
end
