Rails.application.routes.draw do
  root "home#index"
  resources :predial_ags_jms, only: [ :index ] do
    collection do
      post :import
    end
  end
  resources :neodata_records, only: [ :index ] do
    collection do
      post :import
    end
  end
  resources :repeated_exemptions, only: [ :index ]

  get "up" => "rails/health#show", as: :rails_health_check
end
