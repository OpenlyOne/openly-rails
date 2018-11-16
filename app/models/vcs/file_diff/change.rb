# frozen_string_literal: true

module VCS
  class FileDiff
    # A single change of the diff, such as addition or modification
    class Change
      include ActiveModel::Model

      attr_accessor :diff

      # Delegations
      delegate :ancestor_path, :current_snapshot, :current_snapshot=,
               :current_or_previous_snapshot, :file_resource_id, :external_id,
               :icon, :name, :parent_id, :previous_parent_id,
               :previous_snapshot, :symbolic_mime_type, :revision,
               :content_change,
               to: :diff

      delegate :unselected_file_changes, to: :revision

      # Select change on initialization
      def initialize(*args)
        super
        select!
      end

      # Return true if the change is an ::Addition
      def addition?
        type == 'addition'
      end

      # Unapplies the change from the diffed file resource, if the change is not
      # selected
      def apply
        unapply unless selected?
      end

      def color
        "#{base_color} #{color_shade}"
      end

      # Return true if the change is a ::Deletion
      def deletion?
        type == 'deletion'
      end

      # The identifier for the change, consisting of external ID and change type
      def id
        "#{external_id}_#{type}"
      end

      # Return true if the change is a ::Modification
      def modification?
        type == 'modification'
      end

      # Return true if the change is a ::Movement
      def movement?
        type == 'movement'
      end

      def text_color
        color.split(' ').join('-text text-')
      end

      # Return true if the change is a ::Rename
      def rename?
        type == 'rename'
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

      def must_not_unselect_addition_of_parent
        unselected_parent = unselected_file_changes.find do |change|
          change.addition? && change.file_resource_id == parent_id
        end

        return unless unselected_parent

        errors[:base] << "You cannot #{action} '#{name}' without adding its " \
                         "parent folder '#{unselected_parent.name}'"
      end

      def tooltip_base_text
        'File has been'
      end
    end
  end
end
