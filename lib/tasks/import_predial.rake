require "csv"

namespace :import do
  desc "Import Predial CSV data into PredialAgsJM and RepeatedExemption"
  task predial_csv: :environment do
    file_path = Rails.root.join("storage", "DCC-PREDIAL-2026.csv")
    unless File.exist?(file_path)
      puts "No se encontró el archivo en #{file_path}"
      exit 1
    end

    def roman_to_int(roman)
      map = { "I" => 1, "II" => 2, "III" => 3, "IV" => 4, "V" => 5, "VI" => 6, "VII" => 7, "VIII" => 8, "IX" => 9, "X" => 10 }
      map[roman]
    end

    def extract_desarrollo(val)
      return "" if val.nil?
      str = val.strip.upcase

      # Remove known prefixes
      str = str.sub(/\AF\s*\d+\s*/, "") # e.g. "F 101 "
      str = str.sub(/\ARESERVA\s+/, "") # e.g. "RESERVA "

      # Remove leading articles: LA, EL, LOS, LAS
      str = str.sub(/\A(LA|EL|LOS|LAS)\s+/, "")

      # Match trailing roman numeral
      if str =~ /\s+(X|IX|VIII|VII|VI|V|IV|III|II|I)\z/
        roman = $1
        str = str.sub(/\s+#{roman}\z/, roman_to_int(roman).to_s)
      end

      # Remove ALL spaces from the final result
      str.gsub(/\s+/, "")
    end

    imported = 0
    duplicates = 0

    CSV.foreach(file_path, headers: true) do |row|
      cuenta = row["CUENTA"]&.strip
      catastral = row["CATASTRAL"]&.strip
      nombre = row["NOMBRE"]&.strip
      ubicacion = row["UBICACION"]&.strip || row["UBICACIÓN"]&.strip
      raw_desarrollo = row["DESARROLLO"]&.strip
      l_val = row["L"]&.strip
      m_val = row["M"]&.strip

      # Generate extracted value for index construction
      extracted_d = extract_desarrollo(raw_desarrollo)

      # Construct the unique index string
      index_val = "#{extracted_d}-#{m_val}-#{l_val}"

      attributes = {
        cuenta: cuenta,
        catastral: catastral,
        nombre: nombre,
        ubicacion: ubicacion,
        desarrollo: raw_desarrollo,
        l: l_val,
        m: m_val,
        index: index_val
      }

      begin
        # Try to create the main record
        PredialAgsJM.create!(attributes)
        imported += 1
      rescue ActiveRecord::RecordNotUnique
        # If it fails due to unique index violation, save it in RepeatedExemption
        RepeatedExemption.create!(
          attributes.merge(reason: "Duplicate index: #{index_val}")
        )
        duplicates += 1
      end
    end

    puts "Import complete!"
    puts "Successfully imported into PredialAgsJM: #{imported}"
    puts "Saved duplicates to RepeatedExemption: #{duplicates}"
  end
end
