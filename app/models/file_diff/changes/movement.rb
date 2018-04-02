# frozen_string_literal: true

class FileDiff
  module Changes
    # A single change of type movement
    class Movement < Change
      def indicator_icon
        'M14,18V15H10V11H14V8L19,13M20,6H12L10,4H4C2.89,4 2,4.89 2,6V18A2,'\
        '2 0 0,0 4,20H20A2,2 0 0,0 22,18V8C22,6.89 21.1,6 20,6Z'
      end

      def description
        "moved to #{ancestor_path}"
      end

      def tooltip
        "#{tooltip_base_text} moved"
      end

      private

      def base_color
        'purple'
      end

      # Undo movement of the file resource
      def unapply
        current_snapshot.parent_id = previous_snapshot.parent_id
      end
    end
  end
end
