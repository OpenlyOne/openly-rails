# frozen_string_literal: true

class FileDiff
  module Changes
    # A single change of type deletion
    class Deletion < Change
      def indicator_icon
        'M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,2 0 0,0 '\
        '18,19V7H6V19Z'
      end

      def description
        "deleted from #{ancestor_path}"
      end

      def tooltip
        "#{tooltip_base_text} deleted"
      end

      private

      def base_color
        'red'
      end
    end
  end
end
