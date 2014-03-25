MakeSlide::Application.routes.draw do
  require 'api'
  require "api_v2"

  root :to => "home#index"
  get "home/releated_a" => "home#releated_a", :path => "releated_a", as: "home_releated_a"
  get "home/follow_a" => "home#follow_a", :path => "follow_a", as: "home_follow_a"
  get "home/explore" => "home#explore", :path => "explore", as: "home_explore"
  devise_for :users, :path => "account", :controllers => {
      :registrations => :account,
      :sessions => :sessions,
      invitations: "users/invitations",
      :omniauth_callbacks => "users/omniauth_callbacks"
  }

  delete "account/auth/:provider/unbind" => "users#auth_unbind", as: 'unbind_account'
  post "account/update_private_token" => "users#update_private_token", as: 'update_private_token_account'

  resources :notifications, :only => [:index, :destroy] do
    collection do
      post :clear
    end
  end

  get "slides/last" => "slides#recent", as: "recent_slides"
  resources :slides do
    member do
      post :reply
      post :favorite
      get :attachs
      get :download
      patch :suggest
      delete :unsuggest
    end
    collection do
      get :no_reply
      get :popular
      get :excellent
    end
    resources :replies
  end

  resources :attachs, :except => :index do

  end

  resources :photos
  resources :likes

  get "/search" => "search#index", as: 'search'

  namespace :cpanel do
    root :to => "home#index"
    resources :site_configs
    resources :replies
    resources :users
    resources :photos
    resources :locations
  end

  get "api" => "home#api", as: 'api'
  mount MakeSlide::API => "/"
  mount MakeSlide::APIV2 => "/"

  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)

  require 'sidekiq/web'
  # ...
  mount Sidekiq::Web => '/sidekiq'

  # WARRING! 请保持 User 的 routes 在所有路由的最后，以便于可以让用户名在根目录下面使用，而又不影响到其他的 routes
  # 比如 http://makeslide.com/huacnlee
  get "users/city/:id" => "users#city", as: 'location_users'
  post "users/:id/follow" => "users#follow"
  post "users/:id/unfollow" => "users#unfollow"
  get "users" => "users#index", as: 'users'
  resources :users, :path => "" do
    member do
      get :collections
      get :slides
      get :slides_popular
      get :favorite_slides
      get :following
      get :followers
    end
  end

end
