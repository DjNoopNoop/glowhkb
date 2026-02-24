namespace :db do
  desc "Destroy all records in all models except the first User. Requires CONFIRM=YES to run."
  task destroy_all_except_first_user: :environment do
    unless ENV['CONFIRM'] == 'YES'
      puts "This task will destroy data across the database. To run, set CONFIRM=YES"
      puts "Example: bin/rails db:destroy_all_except_first_user CONFIRM=YES"
      next
    end

    Rails.application.eager_load!

    first_user = User.order(:id).first
    puts "Preserving User id=#{first_user&.id || 'none'}"

    # Collect models that map to tables
    models = ActiveRecord::Base.descendants.select do |m|
      m.respond_to?(:table_exists?) && m.table_exists? && !m.abstract_class?
    end

    # Exclude internal AR models
    models.reject! { |m| [ActiveRecord::SchemaMigration, ActiveRecord::InternalMetadata].include?(m) }

    models.each do |model|
      begin
        if model.name == 'User'
          if first_user
            puts "Destroying Users except id=#{first_user.id}..."
            model.where.not(id: first_user.id).find_each(batch_size: 100) { |r| r.destroy }
          else
            puts "No users found — destroying all Users..."
            model.find_each(batch_size: 100) { |r| r.destroy }
          end
        else
          puts "Destroying all #{model.name} records..."
          model.find_each(batch_size: 100) { |r| r.destroy }
        end
      rescue => e
        puts "Failed to clear #{model.name}: #{e.message}"
      end
    end

    puts "Done. All records destroyed except the first User (if present)."
  end
end
