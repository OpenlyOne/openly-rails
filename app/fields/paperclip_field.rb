# frozen_string_literal: true

require 'administrate/field/base'

# Administrate field for managing Paperclip file attachments
class PaperclipField < Administrate::Field::Base
  def url
    data.url
  end

  def thumbnail
    data.url(:thumbnail)
  end

  def to_s
    data
  end
end
