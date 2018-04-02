# frozen_string_literal: true

class FileDiff
  module Changes
    # A single change of type addition
    class Addition < Change
      def description
        "added to #{ancestor_path}"
      end

      def indicator_icon
        'M19,13H13V19H11V13H5V11H11V5H13V11H19V13Z'
      end

      def tooltip
        "#{tooltip_base_text} added"
      end

      private

      def base_color
        'green'
      end

      # Undo addition of the file resource
      def unapply
        self.current_snapshot = nil
      end
    end
  end
end
