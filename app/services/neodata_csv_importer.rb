require "csv"

class NeodataCsvImporter
  include DesarrolloNormalizer

  REQUIRED_HEADERS = %w[Vivienda NombreCliente CódigoCliente NombreProyecto Manzana NumLote].freeze

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

    present_headers = csv_table.headers.compact.map { |h| h.to_s.strip }
    missing_headers = REQUIRED_HEADERS.reject do |req|
      present_headers.any? { |h| h.casecmp(req).zero? || (req == "CódigoCliente" && h.casecmp("CodigoCliente").zero?) }
    end

    if missing_headers.any?
      return Result.new(
        success?: false,
        imported: 0,
        duplicates: 0,
        invalid: 0,
        error_message: "El CSV de Neodata no contiene las columnas requeridas: #{missing_headers.join(', ')}"
      )
    end

    if @replace_existing
      NeodataRecord.delete_all
      RepeatedExemption.where("reason LIKE 'Duplicate Neodata index:%' OR reason LIKE 'Neodata inválido%'").delete_all
    end

    imported = 0
    duplicates = 0
    invalid = 0

    csv_table.each.with_index(2) do |row, line_number|
      next if row.to_h.values.all? { |v| v.to_s.strip.empty? }

      vivienda = row["Vivienda"]&.strip
      nombre_cliente = row["NombreCliente"]&.strip
      codigo_cliente = (row["CódigoCliente"] || row["CodigoCliente"])&.strip
      nombre_proyecto = row["NombreProyecto"]&.strip
      manzana = row["Manzana"]&.strip
      num_lote = row["NumLote"]&.strip

      extracted_d = extract_desarrollo(nombre_proyecto)
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

      record = NeodataRecord.new(attributes)

      begin
        if record.save
          imported += 1
        elsif record.errors.of_kind?(:index, :taken)
          RepeatedExemption.create!(
            index: index_val,
            nombre: nombre_cliente,
            desarrollo: nombre_proyecto,
            m: manzana,
            l: num_lote,
            reason: "Duplicate Neodata index: #{index_val}"
          )
          duplicates += 1
        else
          RepeatedExemption.create!(
            index: index_val,
            nombre: nombre_cliente,
            desarrollo: nombre_proyecto,
            m: manzana,
            l: num_lote,
            reason: "Neodata inválido (línea #{line_number}): #{record.errors.full_messages.join(', ')}"
          )
          invalid += 1
        end
      rescue ActiveRecord::RecordNotUnique
        RepeatedExemption.create!(
          index: index_val,
          nombre: nombre_cliente,
          desarrollo: nombre_proyecto,
          m: manzana,
          l: num_lote,
          reason: "Duplicate Neodata index: #{index_val}"
        )
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

