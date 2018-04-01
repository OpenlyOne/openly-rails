# frozen_string_literal: true

class FileDiff
  # A single change of the diff, such as addition or modification
  class Change
    include ActiveModel::Model

    attr_accessor :diff

    delegate :ancestor_path, :current_or_previous_snapshot, :external_id,
             :icon, :name, :symbolic_mime_type,
             to: :diff

    # Select change on initialization
    def initialize(*args)
      super
      select!
    end

    def color
      "#{base_color} #{color_shade}"
    end

    # The identifier for the change, consisting of external ID and change type
    def id
      "#{external_id}_#{type}"
    end

    def text_color
      color.split(' ').join('-text text-')
    end

    # Mark the change as selected
    def select!
      @selected = true
    end

    # Return true if the change is selected
    def selected?
      @selected
    end

    # Return the type of change, such as 'addition' or 'movement'
    def type
      model_name.element
    end

    # Mark the change as unselected
    def unselect!
      @selected = false
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
