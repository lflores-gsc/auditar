class HomeController < ApplicationController
  def index
    @predial_count = PredialAgsJM.count
    @neodata_count = NeodataRecord.count
    @duplicates_count = RepeatedExemption.count
  end
end
