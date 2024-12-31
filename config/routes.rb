Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
   namespace :api do
    resources :users do
      collection do
        get :reporting_managers
        post :forgot_password
        post :reset_password
      end
    end
    resources :sales_teams
  end
end
