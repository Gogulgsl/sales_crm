Rails.application.routes.draw do
  namespace :api do
    resources :users do
      collection do
        get :reporting_managers
        post :forgot_password
        post :reset_password
      end
    end
    resources :sales_teams
    resources :products do 
      collection do 
        get :active_products
      end
    end 
    resources :schools do
      collection do
        post :upload
        get :active_schools
        get :head_quarters
        post :import_file
      end
      member do
        get :contacts
        put :update_contacts
      end
    end
    resources :opportunities do
      collection do
        post :add_opportunities, to: 'opportunities#create'
        get :active_opportunities
        get :logs
        post :import_file
      end
    end
    resources :auth, only: [] do
      collection do
        post :login
      end
    end    
    resources :daily_statuses
    resources :contacts do 
      collection do 
        get :active_contacts
      end 
    end
  end
end
