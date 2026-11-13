require "csv"

class PredialCsvImporter
  include DesarrolloNormalizer

  REQUIRED_HEADERS = %w[CUENTA CATASTRAL NOMBRE DESARROLLO L M].freeze

  Result = Struct.new(:success?, :imported, :duplicates, :invalid, :error_message, keyword_init: true)

  def initialize(file: nil, file_path: nil, replace_existing: false)
    @file = file
    @file_path = file_path.to_s.strip
    @replace_existing = replace_existing
  end

  def call
    resolved_path = resolve_source_path
    unless resolved_path && File.exist?(resolved_path) && File.file?(resolved_path)
      return Result.new(
        success?: false,
        imported: 0,
        duplicates: 0,
        invalid: 0,
        error_message: "No se encontró un archivo CSV válido. Selecciona un archivo o verifica la ruta local."
      )
    end

    unless File.extname(original_filename(resolved_path)).casecmp(".csv").zero?
      return Result.new(
        success?: false,
        imported: 0,
        duplicates: 0,
        invalid: 0,
        error_message: "El archivo seleccionado debe tener extensión .csv"
      )
    end

    csv_content = read_utf8_content(resolved_path)
    csv_table = CSV.parse(csv_content, headers: true, liberal_parsing: true)

    missing_headers = REQUIRED_HEADERS - csv_table.headers.compact.map { |h| h.to_s.strip.upcase }
    if missing_headers.any?
      return Result.new(
        success?: false,
        imported: 0,
        duplicates: 0,
        invalid: 0,
        error_message: "El CSV de Predial no contiene las columnas requeridas: #{missing_headers.join(', ')}"
      )
    end

    if @replace_existing
      PredialAgsJM.delete_all
      RepeatedExemption.where("reason LIKE 'Duplicate index:%' OR reason LIKE 'Predial inválido%'").delete_all
    end

    imported = 0
    duplicates = 0
    invalid = 0

    csv_table.each.with_index(2) do |row, line_number|
      normalized_row = row.to_h.transform_keys { |k| k.to_s.strip.upcase }
      next if normalized_row.values.all? { |v| v.to_s.strip.empty? }

      cuenta = normalized_row["CUENTA"]&.strip
      catastral = normalized_row["CATASTRAL"]&.strip
      nombre = normalized_row["NOMBRE"]&.strip
      ubicacion = normalized_row["UBICACION"]&.strip || normalized_row["UBICACIÓN"]&.strip
      raw_desarrollo = normalized_row["DESARROLLO"]&.strip
      l_val = normalized_row["L"]&.strip
      m_val = normalized_row["M"]&.strip

      extracted_d = extract_desarrollo(raw_desarrollo)
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

      record = PredialAgsJM.new(attributes)

      begin
        if record.save
          imported += 1
        elsif record.errors.of_kind?(:index, :taken)
          RepeatedExemption.create!(attributes.merge(reason: "Duplicate index: #{index_val}"))
          duplicates += 1
        else
          RepeatedExemption.create!(
            attributes.merge(reason: "Predial inválido (línea #{line_number}): #{record.errors.full_messages.join(', ')}")
          )
          invalid += 1
        end
      rescue ActiveRecord::RecordNotUnique
        RepeatedExemption.create!(attributes.merge(reason: "Duplicate index: #{index_val}"))
        duplicates += 1
      end
    end

    Result.new(
      success?: true,
      imported: imported,
      duplicates: duplicates,
      invalid: invalid,
      error_message: nil
    )
  rescue CSV::MalformedCSVError => e
    Result.new(
      success?: false,
      imported: 0,
      duplicates: 0,
      invalid: 0,
      error_message: "Error de formato en el archivo CSV: #{e.message}"
    )
  end

  private

  def resolve_source_path
    if @file.respond_to?(:tempfile)
      @file.tempfile.path
    elsif @file_path.present?
      expanded = File.expand_path(@file_path, Rails.root)
      File.exist?(@file_path) ? @file_path : expanded
    end
  end

  def original_filename(resolved_path)
    if @file.respond_to?(:original_filename)
      @file.original_filename.to_s
    else
      resolved_path.to_s
    end
  end

  def read_utf8_content(path)
    raw = File.binread(path)
    raw.delete_prefix!("\xEF\xBB\xBF".b)
    content = raw.force_encoding("UTF-8")
    unless content.valid_encoding?
      content = raw.force_encoding("Windows-1252").encode("UTF-8", invalid: :replace, undef: :replace)
    end
    content
  end
end

