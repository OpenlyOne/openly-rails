# frozen_string_literal: true

# Jobs can parse reference into ID and type
module Referenceable
  extend ActiveSupport::Concern

  included do
    before_enqueue :reference_to_type_and_id
  end

  private

  # Transforms a reference object (passed in the arguments to perform_later)
  # into its type and ID, so it can be saved to the database.
  def reference_to_type_and_id
    reference_argument =
      arguments.find { |arg| arg.is_a?(Hash) && arg.key?(:reference) }

    return unless reference_argument

    reference_object = reference_argument[:reference]

    reference_argument
      .except!(:reference)
      .merge!(reference_id: reference_object.id,
              reference_type: reference_object.model_name.param_key)
  end
end
