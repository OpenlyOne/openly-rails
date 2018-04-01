# frozen_string_literal: true

class FileDiff
  # A single change of the diff, such as addition or modification
  class Change
    include ActiveModel::Model

    attr_accessor :diff

    delegate :ancestor_path, :current_or_previous_snapshot, :external_id,
             :icon, :name, :symbolic_mime_type,
             to: :diff

    def color
      "#{base_color} #{color_shade}"
    end

    def text_color
      color.split(' ').join('-text text-')
    end

    def type
      model_name.element
    end

    private

    def color_shade
      'darken-2'
    end

    def tooltip_base_text
      'File has been'
    end
  end
end
