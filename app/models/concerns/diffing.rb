# frozen_string_literal: true

# Add support for diffing file resources
module Diffing
  extend ActiveSupport::Concern

  # Delegations
  delegate :id, to: :current_or_previous_snapshot, prefix: true
  delegate :external_id, :external_link, :folder?, :icon, :mime_type, :name,
           :provider, :provider=, :symbolic_mime_type,
           to: :current_or_previous_snapshot

  delegate_methods = %i[content_version name parent_id]
  delegate(*delegate_methods, to: :current_snapshot, prefix: :current)
  delegate(*delegate_methods, to: :previous_snapshot, prefix: :previous)

  def added?
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

  def changed?
    added? || deleted? || updated?
  end

  # Return the changes that have been made from previous_snapshot to
  # current_snapshot. When file has been updated (moved, renamed, or modified),
  # moved must come first in the list of changes, renamed second, and modified
  # last.
  def changes
    @changes ||=
      %i[added deleted moved renamed modified].select do |change|
        send("#{change}?")
      end
  end

  def deleted?
    current_snapshot_id.nil?
  end

  def modified?
    return false unless updated?
    current_content_version != previous_content_version
  end

  def moved?
    return false unless updated?
    current_parent_id != previous_parent_id
  end

  def renamed?
    return false unless updated?
    current_name != previous_name
  end

  def updated?
    return false if added? || deleted?
    current_snapshot_id != previous_snapshot_id
  end

  def current_or_previous_snapshot
    current_snapshot || previous_snapshot
  end
end
