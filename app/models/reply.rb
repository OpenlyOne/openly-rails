# frozen_string_literal: true

# A single reply in a discussion about a contribution
class Reply < ApplicationRecord
  belongs_to :author, class_name: 'Profiles::User'
  belongs_to :contribution

  validates :content, presence: true
end
