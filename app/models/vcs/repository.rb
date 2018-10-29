module VCS
  class Repository < ApplicationRecord
    has_many :branches, dependent: :destroy
  end
end
