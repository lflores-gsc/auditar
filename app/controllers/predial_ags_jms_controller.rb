class PredialAgsJmsController < ApplicationController
  PER_PAGE_OPTIONS = [ 10, 25, 50, 100, 250 ].freeze

  def index
    @per_page = PER_PAGE_OPTIONS.include?(params[:per_page].to_i) ? params[:per_page].to_i : 25
    @records = PredialAgsJM.order(:index).page(params[:page]).per(@per_page)
  end

  def import
    result = PredialCsvImporter.new(
      file: params[:file],
      file_path: params[:file_path],
      replace_existing: params[:replace_existing] == "1"
    ).call

    if result.success?
      redirect_to predial_ags_jms_path,
        notice: "Importación de Predial completada: #{result.imported} importados, #{result.duplicates} duplicados, #{result.invalid} inválidos."
    else
      redirect_to root_path, alert: result.error_message
    end
  end
end
