Rails.application.routes.draw do
  root "home#index"
  resources :predial_ags_jms, only: [:index]
  resources :neodata_records, only: [:index]
  resources :repeated_exemptions, only: [:index]

  get "up" => "rails/health#show", as: :rails_health_check
end
