class NeodataRecordsController < ApplicationController
  def index
    @records = NeodataRecord.all.order(:index)
  end
end
