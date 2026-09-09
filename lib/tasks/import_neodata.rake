require "csv"

namespace :import do
  desc "Import Neodata CSV data into NeodataRecord"
  task neodata_csv: :environment do
    file_path = Rails.root.join("storage", "concentrado-gsc.csv")
    unless File.exist?(file_path)
      puts "File not found at #{file_path}"
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
      vivienda = row["Vivienda"]&.strip
      nombre_cliente = row["NombreCliente"]&.strip
      codigo_cliente = row["CódigoCliente"]&.strip
      nombre_proyecto = row["NombreProyecto"]&.strip
      manzana = row["Manzana"]&.strip
      num_lote = row["NumLote"]&.strip

      # Generate extracted value for index construction from NombreProyecto
      extracted_d = extract_desarrollo(nombre_proyecto)
      
      # Construct the unique index string matching Predial logic
      index_val = "#{extracted_d}-#{manzana}-#{num_lote}"

      attributes = {
        vivienda: vivienda,
        nombre_cliente: nombre_cliente,
        codigo_cliente: codigo_cliente,
        nombre_proyecto: nombre_proyecto,
        manzana: manzana,
        num_lote: num_lote,
        index: index_val
      }

      begin
        NeodataRecord.create!(attributes)
        imported += 1
      rescue ActiveRecord::RecordNotUnique
        # Save to RepeatedExemption just like Predial
        RepeatedExemption.create!(
          index: index_val,
          reason: "Duplicate Neodata index: #{index_val}"
        )
        duplicates += 1
      end
    end

    puts "Import complete!"
    puts "Successfully imported into NeodataRecord: #{imported}"
    puts "Saved duplicates to RepeatedExemption: #{duplicates}"
  end
end
