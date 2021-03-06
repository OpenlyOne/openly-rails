# frozen_string_literal: true

module VCS
  # Add support for diffing file versions
  module Diffing
    extend ActiveSupport::Concern

    # Delegations
    delegate :id, to: :current_or_previous_version, prefix: true
    delegate :remote_file_id, :link_to_remote, :file, :file_id, :folder?,
             :hashed_file_id, :icon, :mime_type, :name, :parent_id, :provider,
             :symbolic_mime_type, :thumbnail_id, :thumbnail_image,
             :thumbnail_image_or_fallback,
             to: :current_or_previous_version

    delegate_methods = %i[content_version name parent_id parent_id
                          file_id content_id plain_text_content]
    delegate(*delegate_methods,
             to: :current_version, prefix: :current, allow_nil: true)
    delegate(*delegate_methods,
             to: :previous_version, prefix: :previous, allow_nil: true)

    delegate :color, :text_color, to: :primary_change, allow_nil: true

    def addition?
      previous_version_id.nil?
    end

    # Format first_three_ancestors into a path, joined by >
    # 0 ancestors: Home
    # 1-2 ancestors: Ancestor2 > Ancestor1
    # 3(+) ancestors: .. > Ancestor2 > Ancestor1
    def ancestor_path
      case first_three_ancestors.length
      when 0
        'Home'
      when 1, 2
        first_three_ancestors.reverse.join(' > ')
      else
        first_three_ancestors.reverse.drop(1).unshift('..').join(' > ')
      end
    end

    def association(association_name)
      return super unless association_name == :thumbnail

      current_or_previous_version.association(association_name)
    end

    def change?
      addition? || deletion? || update?
    end

    # Return changes made to this diff as an array of symbols. When file has
    # been updated (moved, renamed, or modified), moved must come first in the
    # list of changes, renamed second, and modified last.
    def change_types
      %i[addition deletion movement rename modification].select do |change|
        send("#{change}?")
      end
    end

    # Return the changes that have been made from previous_version to
    # current_version as an array of FileDiff::Change instances.
    def changes
      @changes ||=
        change_types.map do |type|
          "VCS::FileDiff::Changes::#{type.to_s.humanize}"
            .constantize.new(diff: self)
        end
    end

    # Return an instance of ContentDiffer for diffing the previous and current
    # text contents of this diff
    def content_change
      return nil if previous_plain_text_content.nil?
      return nil if current_plain_text_content.nil?

      @content_change ||=
        VCS::Operations::ContentDiffer.new(
          new_content: current_plain_text_content,
          old_content: previous_plain_text_content
        )
    end

    def deletion?
      current_version_id.nil?
    end

    def modification?
      return false unless update?

      current_content_id != previous_content_id
    end

    def movement?
      return false unless update?

      current_parent_id != previous_parent_id
    end

    # The first change is the primary change
    def primary_change
      changes.first
    end

    def rename?
      return false unless update?

      current_name != previous_name
    end

    def update?
      return false if addition? || deletion?

      current_version_id != previous_version_id
    end

    def current_or_previous_version
      current_version || previous_version
    end
  end
end
