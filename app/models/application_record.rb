# frozen_string_literal: true

# Base class for all app models
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Update attributes with validation context.
  # In Rails you can provide a context while you save, for example:
  # `.save(:step1)`, but no way to provide a context while you update. This
  # method just adds the way to update with validation context.
  #
  # @param [Hash] attributes to assign
  # @param [Symbol] validation context
  def update_with_context(attributes, context)
    with_transaction_returning_status do
      assign_attributes(attributes)
      save(context: context)
    end
  end
end
