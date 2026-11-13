namespace :import do
  desc "Import Predial CSV data into PredialAgsJM and RepeatedExemption (optional FILE=/path/to/file.csv)"
  task predial_csv: :environment do
    file_path = ENV.fetch("FILE", Rails.root.join("storage", "DCC-PREDIAL-2026.csv").to_s)
    result = PredialCsvImporter.new(file_path: file_path).call

    unless result.success?
      puts result.error_message
      exit 1
    end

    puts "Import complete!"
    puts "Successfully imported into PredialAgsJM: #{result.imported}"
    puts "Saved duplicates to RepeatedExemption: #{result.duplicates}"
    puts "Saved invalid rows to RepeatedExemption: #{result.invalid}"
  end
end
