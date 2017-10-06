# frozen_string_literal: true

# Replies are responses to discussions, such as suggestions, issues, and
# questions
class Reply < ApplicationRecord
  # Associations
  belongs_to :author, class_name: 'User'
  belongs_to :discussion, class_name: 'Discussions::Base'

  # Validations
  validates :content, presence: true
end
