class RenameUsersNameToUsername < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        rename_column :users, :name, :username
      end

      dir.down do
        rename_column :users, :username, :name
      end
    end
  end
end
