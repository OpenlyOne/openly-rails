# frozen_string_literal: true

module FileItems
  # FileItems of type folder (identified by MIME type)
  class Folder < Base
    has_many :children, class_name: 'FileItems::Base',
                        foreign_key: 'parent_id',
                        dependent: :destroy,
                        inverse_of: :parent
  end
end
