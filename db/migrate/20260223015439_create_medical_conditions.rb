class CreateMedicalConditions < ActiveRecord::Migration[7.1]
  def change
    create_table :medical_conditions do |t|
      t.string  :name, null: false
      t.timestamps
    end
  end
end
