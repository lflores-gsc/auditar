namespace :import do
  desc "Import Neodata CSV data into NeodataRecord and RepeatedExemption (optional FILE=/path/to/file.csv)"
  task neodata_csv: :environment do
    file_path = ENV.fetch("FILE", Rails.root.join("storage", "concentrado-gsc.csv").to_s)
    result = NeodataCsvImporter.new(file_path: file_path).call

    unless result.success?
      puts result.error_message
      exit 1
    end

    puts "Import complete!"
    puts "Successfully imported into NeodataRecord: #{result.imported}"
    puts "Saved duplicates to RepeatedExemption: #{result.duplicates}"
    puts "Saved invalid rows to RepeatedExemption: #{result.invalid}"
  end
end
