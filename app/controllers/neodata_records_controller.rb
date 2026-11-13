class NeodataRecordsController < ApplicationController
  PER_PAGE_OPTIONS = [ 10, 25, 50, 100, 250 ].freeze

  def index
    @per_page = PER_PAGE_OPTIONS.include?(params[:per_page].to_i) ? params[:per_page].to_i : 25
    @records = NeodataRecord.order(:index).page(params[:page]).per(@per_page)
  end

  def import
    result = NeodataCsvImporter.new(
      file: params[:file],
      file_path: params[:file_path],
      replace_existing: params[:replace_existing] == "1"
    ).call

    if result.success?
      redirect_to neodata_records_path,
        notice: "Importación de Neodata completada: #{result.imported} importados, #{result.duplicates} duplicados, #{result.invalid} inválidos."
    else
      redirect_to root_path, alert: result.error_message
    end
  end
end
