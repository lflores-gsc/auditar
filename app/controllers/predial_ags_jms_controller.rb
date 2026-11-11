class PredialAgsJmsController < ApplicationController
  PER_PAGE_OPTIONS = [ 10, 25, 50, 100, 250 ].freeze

  def index
    @per_page = PER_PAGE_OPTIONS.include?(params[:per_page].to_i) ? params[:per_page].to_i : 25
    @records = PredialAgsJM.order(:index).page(params[:page]).per(@per_page)
  end
end
