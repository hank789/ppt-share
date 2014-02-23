RubyChina::Application.routes.draw do
  require 'api'
  require "api_v2"
  
  resources :sites
  resources :pages, :path => "wiki" do
    collection do
      get :recent
      post :preview
    end
    member do
      get :comments
    end
  end
  resources :comments
  resources :notes do
    collection do
      post :preview
    end
  end
  root :to => "home#index"

  devise_for :users, :path => "account", :controllers => {
      :registrations => :account,
      :sessions => :sessions,
      :omniauth_callbacks => "users/omniauth_callbacks"
    }

  delete "account/auth/:provider/unbind" => "users#auth_unbind", as: 'unbind_account'
  post "account/update_private_token" => "users#update_private_token", as: 'update_private_token_account'

  resources :notifications, :only => [:index, :destroy] do
    collection do
      post :clear
    end
  end

	resources :folders
	
 	resources :slides do
		member do 
			post :reply
			post :favorite
			get :download
			get :attachs
		end
		collection do
			get :no_reply
			get :popular
		end
		resources :replies
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
  mount RubyChina::API => "/"
  mount RubyChina::APIV2 => "/"

  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)

	require 'sidekiq/web'
	# ...
	mount Sidekiq::Web, at: '/sidekiq'

  # WARRING! 请保持 User 的 routes 在所有路由的最后，以便于可以让用户名在根目录下面使用，而又不影响到其他的 routes
  # 比如 http://saashow.com/huacnlee
  get "users/city/:id" => "users#city", as: 'location_users'
  get "users" => "users#index", as: 'users'
  resources :users, :path => "" do
    member do
			get :slides
      get :likes
			get :collections
      get :workspace
    end
  end

end
