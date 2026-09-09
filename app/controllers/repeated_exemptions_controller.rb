class RepeatedExemptionsController < ApplicationController
  def index
    @records = RepeatedExemption.all.order(created_at: :desc)
  end
end
