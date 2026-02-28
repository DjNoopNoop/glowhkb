class AddSubmissionToPublications < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:publications, :submission_id)
      add_reference :publications, :submission, foreign_key: true, type: :bigint
    else
      # ensure foreign key exists if the column was added previously
      unless foreign_key_exists?(:publications, :submissions)
        add_foreign_key :publications, :submissions
      end
    end

    add_index :publications, :submission_id unless index_exists?(:publications, :submission_id)
  end
end
