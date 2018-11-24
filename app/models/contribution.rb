# frozen_string_literal: true

# A contribution to a project (equivalent of pull request/merge request)
class Contribution < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'Profiles::User'

  # Validations
  validates :title, presence: true
  validates :description, presence: true
end
