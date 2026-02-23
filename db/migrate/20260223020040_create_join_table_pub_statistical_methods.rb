class CreateJoinTablePubStatisticalMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :pub_statistical_methods, id: false do |t|
      t.bigint :publication_id, null: false
      t.bigint :statistical_method_id, null: false
    end
    add_index :pub_statistical_methods, [:publication_id, :statistical_method_id], name: 'idx_pub_sm'
    add_index :pub_statistical_methods, [:statistical_method_id, :publication_id], name: 'idx_sm_pub'
  end
end
