# frozen_string_literal: true

# Base class for all app jobs
class ApplicationJob < ActiveJob::Base
  before_enqueue :reference_to_type_and_id

  private

  # Transforms a reference object (passed in the arguments to perform_later)
  # into its type and ID, so it can be saved to the database.
  def reference_to_type_and_id
    return unless arguments[0]&.keys&.include? :reference

    reference = arguments[0][:reference]

    arguments[0]
      .except!(:reference)
      .merge!(reference_id: reference.id,
              reference_type: reference.model_name.param_key)
  end
end
