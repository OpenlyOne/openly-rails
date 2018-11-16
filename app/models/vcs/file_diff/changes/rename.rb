# frozen_string_literal: true

module VCS
  class FileDiff
    module Changes
      # A single change of type rename
      class Rename < Change
        delegate :previous_name, to: :diff

        def indicator_icon
          'M3,12H6V19H9V12H12V9H3M9,4V7H14V19H17V7H22V4H9Z'
        end

        def description
          "renamed from '#{previous_name}' in #{ancestor_path}"
        end

        def tooltip
          "#{tooltip_base_text} renamed"
        end

        private

        def base_color
          'blue'
        end

        # Undo rename of the file resource
        def unapply
          current_snapshot.name = previous_snapshot.name
        end
      end
    end
  end
end
