# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  # Error routing
  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unacceptable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  devise_for :accounts, skip: %i[registrations sessions]

  # Routes for signups
  post '/signup' => 'signups#create'

  # Routes for registration
  if Settings.enable_account_registration
    devise_scope :account do
      get   '/join' => 'devise/registrations#new',
            :as     => :new_registration
      post  '/join' => 'devise/registrations#create',
            :as     => :registration
    end
  end

  # Routes for account management
  devise_scope :account do
    resource :account,
             only: %i[edit update destroy],
             path_names: { edit: '' },
             controller: 'devise/registrations'
    # Stay on /account page after user updates their account
    get '/account', to: 'devise/registrations#edit', as: :account_root
  end

  # Routes for sessions
  devise_scope :account do
    get   '/login'  => 'devise/sessions#new',
          :as       => :new_session
    post  '/login'  => 'devise/sessions#create',
          :as       => :session
    get   '/logout' => 'devise/sessions#destroy',
          :as       => :destroy_session
  end

  # Redirect to login path when user is unauthenticated
  get '/login' => 'devise/sessions#new', :as => :new_account_session

  # Routes for creating new projects
  get   '/projects/new' => 'projects#new',    as: :new_project
  post  '/projects/new' => 'projects#create', as: :projects

  # Routes for user profiles (must be last)
  resources :profiles, path: '/', only: %i[show edit update], param: :handle

  # Routes for existing projects (must be last)
  resources :profiles, path: '/', only: [], param: :handle do
    # Routes for existing projects (must be last)
    resources :projects,
              path: '/', except: %i[index new create], param: :slug do
      get  'setup'  => 'projects#setup',  on: :member
      post 'import' => 'projects#import', on: :member
      # Routes for folders
      get 'files' => 'folders#root', as: :root_folder
      resources :folders, only: :show
      # Routes for revisions
      resources :revisions, only: %i[index new create]
      # Routes for file infos
      resources :file_infos, path: 'files/:id/info', only: :index
      resources :force_syncs, path: 'files/:id/sync', only: :create
    end
  end

  root 'static#index'
end
