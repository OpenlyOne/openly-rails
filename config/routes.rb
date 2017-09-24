# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

Rails.application.routes.draw do
  # Error routing
  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unacceptable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

  devise_for :accounts, skip: %i[registrations sessions]

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
  resources :profiles, path: '/', only: :show, param: :handle do
    # Routes for existing projects (must be last)
    resources :projects,
              path: '/', except: %i[index new create], param: :slug do
      # Routes for project files
      resources :files,
                only: %i[index new create show], param: :name,
                constraints: { name: %r{[^/]+} } do
                  get     'edit'    => 'files#edit_content',    on: :member
                  patch   'edit'    => 'files#update_content',  on: :member
                  put     'edit'    => 'files#update_content',  on: :member
                  get     'rename'  => 'files#edit_name',       on: :member
                  patch   'rename'  => 'files#update_name',     on: :member
                  put     'rename'  => 'files#update_name',     on: :member
                  get     'delete'  => 'files#delete',          on: :member
                  delete  'delete'  => 'files#destroy',         on: :member
                end
      # Route for discussions
      resources :discussions,
                path: '/:type', only: %i[index new create show],
                constraints: { type: /suggestions|issues/ }
    end
  end

  root 'static#index'
end
