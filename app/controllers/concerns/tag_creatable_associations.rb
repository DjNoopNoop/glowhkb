# app/models/concerns/tag_creatable_associations.rb
module TagCreatableAssociations
  extend ActiveSupport::Concern

  class_methods do
    # Example:
    # tag_creatable_habtm :air_pollutants, param_key: :air_pollutant_ids
    def tag_creatable_habtm(association_name, param_key:)
      define_method("apply_#{param_key}_with_tag_creation!") do |raw_values|
        ids = normalize_ids_with_creation(association_name, raw_values)
        public_send("#{param_key}=", ids)
      end
    end
  end

  private

  # Converts ["1", "Ozone", "3"] => [1, <id for Ozone>, 3]
  def normalize_ids_with_creation(association_name, raw_values)
    return [] if raw_values.blank?

    model_class = self.class.reflect_on_association(association_name)&.klass
    raise ArgumentError, "Unknown association: #{association_name}" unless model_class

    raw_values
      .reject(&:blank?)
      .map { |v| v.is_a?(String) ? v.strip : v }
      .map do |value|
        if integer_string?(value)
          value.to_i
        else
          record = model_class.where("LOWER(name) = ?", value.to_s.downcase).first
          record ||= model_class.create!(name: value.to_s)
          record.id
        end
      end
      .uniq
  end

  def integer_string?(value)
    return false unless value.is_a?(String) || value.is_a?(Numeric)
    str = value.to_s
    str.to_i.to_s == str
  end
end