# Base class for all app models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
