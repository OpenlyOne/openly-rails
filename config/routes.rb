# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :accounts, skip: [:registrations]

  # Routes for registration
  devise_scope :account do
    get   '/join' => 'devise/registrations#new',
          :as     => :new_registration
    post  '/join' => 'devise/registrations#create',
          :as     => :registration
  end

  # Routes for account management
  devise_scope :account do
    resource :account,
             only: %i[edit update destroy],
             path_names: { edit: '' },
             controller: 'devise/registrations'
  end

  root 'static#index'
end
