# frozen_string_literal: true

Rails.application.routes.draw do
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

  root 'static#index'
end
