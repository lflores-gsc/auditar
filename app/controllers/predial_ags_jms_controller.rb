class PredialAgsJmsController < ApplicationController
  def index
    @records = PredialAgsJM.all.order(:index)
  end
end
