# frozen_string_literal: true

module VCS
  class FileDiff
    module Changes
      # A single change of type deletion
      class Deletion < Change
        validate :must_not_unselect_deletion_of_children
        validate :must_not_unselect_movement_of_children

        def indicator_icon
          'M19,4H15.5L14.5,3H9.5L8.5,4H5V6H19M6,19A2,2 0 0,0 8,21H16A2,' \
          '2 0 0,0 18,19V7H6V19Z'
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

        def must_not_unselect_deletion_of_children
          unselected_children = unselected_file_changes.select do |change|
            change.deletion? && change.parent_id == file_resource_id
          end

          return unless unselected_children.any?

          errors[:base] << "You cannot delete '#{name}' without deleting its " \
                           'contents: ' \
                           "#{unselected_children.map(&:name).to_sentence}"
        end

        def must_not_unselect_movement_of_children
          unselected_children = unselected_file_changes.select do |change|
            change.movement? && change.previous_parent_id == file_resource_id
          end

          return unless unselected_children.any?

          errors[:base] << "You cannot delete '#{name}' without moving its " \
                           'contents: ' \
                           "#{unselected_children.map(&:name).to_sentence}"
        end

        # Undo deletion of the file resource
        def unapply
          self.current_version = previous_version
        end
      end
    end
  end
end
