# Base class for all app controllers
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
