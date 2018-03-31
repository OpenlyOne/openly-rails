# frozen_string_literal: true

class FileDiff
  # A single change of the diff, such as addition or modification
  class Change
    include ActiveModel::Model

    attr_accessor :diff, :type

    delegate :ancestor_path, :current_or_previous_snapshot, :external_id,
             :icon, :name, :symbolic_mime_type,
             to: :diff
  end
end
