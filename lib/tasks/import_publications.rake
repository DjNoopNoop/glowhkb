# Rake tasks to import CSVs into models
require 'csv'

namespace :import do
  # Read a CSV file robustly: read raw bytes, force UTF-8 and scrub invalid sequences
  def each_csv_row(path)
    content = File.open(path, 'rb', &:read)
    content = content.force_encoding('UTF-8')
    content = content.scrub('')
    CSV.parse(content, headers: true).each do |row|
      yield row
    end
  end

  # Find (case-insensitive) or create a record by name. Tries exact lowercase match,
  # exact match, then ILIKE partial match, then creates the record if none found.
  def find_or_create_by_name(model_cls, raw_name)
    return nil if raw_name.nil?
    name = raw_name.to_s.strip
    return nil if name.empty?
    rec = model_cls.where('LOWER(name) = ?', name.downcase).first
    rec ||= model_cls.find_by(name: name)
    rec ||= model_cls.where('name ILIKE ?', "%#{name}%").first
    return rec if rec
    model_cls.create!(name: name)
  rescue => e
    puts "Failed to find/create #{model_cls.name} for '#{raw_name}': #{e.message}"
    nil
  end

  desc "Create csv_imports directory where CSV files should be placed"
  task :setup do
    dir = Rails.root.join('csv_imports')
    unless Dir.exist?(dir)
      FileUtils.mkdir_p(dir)
      puts "Created #{dir}"
    else
      puts "Directory already exists: #{dir}"
    end
    puts "Place CSV files into #{dir} and then run `rake import:all`"
  end

  desc "Import all CSV files found in csv_imports into the database"
  task all: :environment do
    dir = Rails.root.join('csv_imports')
    unless Dir.exist?(dir)
      puts "Directory not found: #{dir}. Run `rake import:setup` to create it and add CSVs."
      next
    end

    files = {
      # singular/plural variants observed in csv_imports
      'air_pollutant.csv' => :import_air_pollutants,
      'geo_location.csv' => :import_geographic_locations,
      'med_condition.csv' => :import_medical_conditions,
      'statistical_method.csv' => :import_statistical_methods,
      'weather_parameter.csv' => :import_weather_parameters,
      'publication.csv' => :import_publications,

      # publication association tables (attach by id or name)
      'pub_air_pollutant.csv' => :import_publication_air_pollutants,
      'pub_geo_location.csv' => :import_publication_geo_locations,
      'pub_med_condition.csv' => :import_publication_med_conditions,
      'pub_statistical_method.csv' => :import_publication_statistical_methods,
      'pub_weather_parameter.csv' => :import_publication_weather_parameters
    }

    files.each do |filename, task_name|
      path = dir.join(filename)
      if File.exist?(path)
        Rake::Task["import:#{task_name}"].reenable
        Rake::Task["import:#{task_name}"].invoke(path.to_s)
      else
        puts "Skipping #{filename} — not present in #{dir}"
      end
    end
  end

  task :import_air_pollutants, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      name = row['air_pollutant'].to_s.strip
      next if name.empty?
      AirPollutant.find_or_create_by!(name: name)
      count += 1
    end
    puts "Imported/ensured #{count} air_pollutants from #{path}"
  end

  task :import_weather_parameters, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      name = row['weather_parameter'].to_s.strip
      next if name.empty?
      WeatherParameter.find_or_create_by!(name: name)
      count += 1
    end
    puts "Imported/ensured #{count} weather_parameters from #{path}"
  end

  task :import_medical_conditions, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      name = ['med_condition_name'].to_s.strip
      next if name.empty?
      MedicalCondition.find_or_create_by!(name: name)
      count += 1
    end
    puts "Imported/ensured #{count} medical_conditions from #{path}"
  end

  task :import_statistical_methods, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      name = row['statistical_method'].to_s.strip
      next if name.empty?
      StatisticalMethod.find_or_create_by!(name: name)
      count += 1
    end
    puts "Imported/ensured #{count} statistical_methods from #{path}"
  end

  task :import_geographic_locations, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      name = row['geo_location_name'].to_s.strip
      next if name.empty?
      GeographicLocation.find_or_create_by!(name: name)
      count += 1
    end
    puts "Imported/ensured #{count} geographic_locations from #{path}"
  end

  # Attach publications -> air_pollutants by publication_id and pollutant id/name
  task :import_publication_air_pollutants, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      pub_id = row['publication_id'] || row['publicationId']
      next unless pub_id
      pub = Publication.find_by(id: pub_id.to_i)

      unless pub
        puts "Publication not found for id=#{pub_id}, skipping row"
        next
      end

      ap = nil
      if (apid = row['air_pollutant_id']) && apid.to_s.strip != ''
        ap = AirPollutant.find_by(id: apid.to_i)
      end
      ap ||= find_or_create_by_name(AirPollutant, row['air_pollutant']) if row['air_pollutant']
      if ap
        pub.air_pollutants << ap unless pub.air_pollutants.exists?(ap.id)
        count += 1
      else
        puts "AirPollutant not found for row: #{row.to_h.inspect}"
      end
    end
    puts "Attached #{count} air_pollutant associations from #{path}"
  end

  task :import_publication_geo_locations, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      pub_id = row['publication_id'] || row['publicationId']
      next unless pub_id
      pub = Publication.find_by(id: pub_id.to_i)
      unless pub
        puts "Publication not found for id=#{pub_id}, skipping row"
        next
      end

      gl = nil
      if (glid = row['geoLocation_id']) && glid.to_s.strip != ''
        gl = GeographicLocation.find_by(id: glid.to_i)
      end
      gl ||= find_or_create_by_name(GeographicLocation, row['geo_location'])
      if gl
        pub.geographic_location = gl
        pub.save! if pub.changed?
        count += 1
      else
        puts "GeographicLocation not found for row: #{row.to_h.inspect}"
      end
    end
    puts "Attached/updated #{count} geographic_location associations from #{path}"
  end

  task :import_publication_med_conditions, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      pub_id = row['publication_id']
      next unless pub_id
      pub = Publication.find_by(id: pub_id.to_i)
      unless pub
        puts "Publication not found for id=#{pub_id}, skipping row"
        next
      end

      mc = nil
      if (mcid = row['med_condition_id']) && mcid.to_s.strip != ''
        mc = MedicalCondition.find_by(id: mcid.to_i)
      end
      mc ||= find_or_create_by_name(MedicalCondition, row['med_condition_name'])
      if mc
        pub.medical_conditions << mc unless pub.medical_conditions.exists?(mc.id)
        count += 1
      else
        puts "MedicalCondition not found for row: #{row.to_h.inspect}"
      end
    end
    puts "Attached #{count} medical_condition associations from #{path}"
  end

  task :import_publication_statistical_methods, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      pub_id = row['publication_id']
      next unless pub_id
      pub = Publication.find_by(id: pub_id.to_i)
      unless pub
        puts "Publication not found for id=#{pub_id}, skipping row"
        next
      end

      sm = nil
      if (smid = row['statistical_method_id']) && smid.to_s.strip != ''
        sm = StatisticalMethod.find_by(id: smid.to_i)
      end
      sm ||= find_or_create_by_name(StatisticalMethod, row['statistical_method'])
      if sm
        pub.statistical_methods << sm unless pub.statistical_methods.exists?(sm.id)
        count += 1
      else
        puts "StatisticalMethod not found for row: #{row.to_h.inspect}"
      end
    end
    puts "Attached #{count} statistical_method associations from #{path}"
  end

  task :import_publication_weather_parameters, [:path] => :environment do |_t, args|
    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      pub_id = row['publication_id']
      next unless pub_id
      pub = Publication.find_by(id: pub_id.to_i)
      unless pub
        puts "Publication not found for id=#{pub_id}, skipping row"
        next
      end

      wp = nil
      if (wpid = row['weather_id']) && wpid.to_s.strip != ''
        wp = WeatherParameter.find_by(id: wpid.to_i)
      end
      wp ||= find_or_create_by_name(WeatherParameter, row['weather_parameter'])
      if wp
        pub.weather_parameters << wp unless pub.weather_parameters.exists?(wp.id)
        count += 1
      else
        puts "WeatherParameter not found for row: #{row.to_h.inspect}"
      end
    end
    puts "Attached #{count} weather_parameter associations from #{path}"
  end

  # publications.csv expected headers:
  # title, authors, journal, year, doi, url, geographic_location, user_email,
  # air_pollutants, weather_parameters, medical_conditions, statistical_methods
  task :import_publications, [:path] => :environment do |_t, args|
    user_id = User.first.id # Associate imported publications with the first user by default

    path = args[:path]
    count = 0
      each_csv_row(path) do |row|
      begin
        title = row['title'].to_s.strip
        next if title.empty?

        pub_attrs = {
          id: row['publication_id'],
          title: title,
          authors: row['authors'],
          journal: row['journal'],
          year: (row['year'].to_i if row['year']),
          doi: row['doi'],
          user_id: user_id
        }

        publication = Publication.find_or_initialize_by(title: pub_attrs[:title])
        publication.assign_attributes(pub_attrs)

        # Only assign publication attributes from the CSV here.
        # Associations (geographic location, air_pollutants, weather_parameters,
        # medical_conditions, statistical_methods) are handled by separate tasks
        # that process the `pub_*.csv` files.
        publication.save!
        count += 1
      rescue => e
        puts "Failed to import publication row (title: #{row['title']}): #{e.message}"
        next
      end
    end
    puts "Imported/updated #{count} publications from #{path}"
  end
end
