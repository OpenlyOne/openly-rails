# frozen_string_literal: true

# Add support for diffing file resources
module Diffing
  extend ActiveSupport::Concern

  # Delegations
  delegate :id, to: :current_or_previous_snapshot, prefix: true
  delegate :external_id, :external_link, :folder?, :icon, :mime_type, :name,
           :parent_id, :provider, :symbolic_mime_type, :thumbnail_id,
           :thumbnail_image, :thumbnail_image_or_fallback,
           to: :current_or_previous_snapshot

  delegate_methods = %i[content_version name parent_id]
  delegate(*delegate_methods, to: :current_snapshot, prefix: :current)
  delegate(*delegate_methods, to: :previous_snapshot, prefix: :previous)

  delegate :color, :text_color, to: :primary_change, allow_nil: true

  def addition?
    previous_snapshot_id.nil?
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
    when 3
      first_three_ancestors.reverse.drop(1).unshift('..').join(' > ')
    end
  end

  def association(association_name)
    return super unless association_name == :thumbnail
    current_or_previous_snapshot.association(association_name)
  end

  def change?
    addition? || deletion? || update?
  end

  # Return changes made to this diff as an array of symbols. When file has been
  # updated (moved, renamed, or modified), moved must come first in the list of
  # changes, renamed second, and modified last.
  def change_types
    %i[addition deletion movement rename modification].select do |change|
      send("#{change}?")
    end
  end

  # Return the changes that have been made from previous_snapshot to
  # current_snapshot as an array of FileDiff::Change instances.
  def changes
    @changes ||=
      change_types.map do |type|
        "FileDiff::Changes::#{type.to_s.humanize}".constantize.new(diff: self)
      end
  end

  def deletion?
    current_snapshot_id.nil?
  end

  def modification?
    return false unless update?
    current_content_version != previous_content_version
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
    current_snapshot_id != previous_snapshot_id
  end

  def current_or_previous_snapshot
    current_snapshot || previous_snapshot
  end
end
