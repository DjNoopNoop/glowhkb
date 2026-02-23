class CreateJoinTablePubMedicalConditions < ActiveRecord::Migration[7.1]
  def change
    create_table :pub_medical_conditions, id: false do |t|
      t.bigint :publication_id, null: false
      t.bigint :medical_condition_id, null: false
    end
    add_index :pub_medical_conditions, [:publication_id, :medical_condition_id], name: 'idx_pub_mc'
    add_index :pub_medical_conditions, [:medical_condition_id, :publication_id], name: 'idx_mc_pub'
  end
end
