Rails.application.routes.draw do
  root "home#index"
  resources :predial_ags_jms, only: [:index]

  get "up" => "rails/health#show", as: :rails_health_check
end
