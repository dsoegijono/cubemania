begin
  default_puzzle = Puzzle.default.slug
rescue # if there's no database yet, it shouldn't crash creating one
  default_puzzle = 1
end

Cubemania::Application.routes.draw do
  root :to => 'homes#show'

  match "/delayed_job" => DelayedJobWeb, :anchor => false

  namespace :api do
    resources :users do
      post :block, :on => :member
    end
    resources :puzzles do
      resources :singles do
        get :grouped, :on => :collection
      end
      resources :records
    end
  end

  resources :posts do
    resources :comments, :only => [:create, :destroy]
  end

  resources :users

  resources :puzzles, :defaults => { :puzzle_id => default_puzzle } do
    resources :records, :only => [:show, :index] do
      get :share, :on => :member
    end

    resource :timer
  end

  resources :kinds

  resource :reset_password, :only => [:new, :create]

  resource :session
  match 'login' => 'sessions#new', :as => 'login'
  match 'logout' => 'sessions#destroy', :as => 'logout'
  match 'register' => 'users#new', :as => 'register'
end
