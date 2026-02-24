class MedicalCondition < ApplicationRecord
  has_and_belongs_to_many :publications, join_table: 'pub_medical_conditions'

  validates :name, presence: true, uniqueness: { case_sensitive: false}
end
