# frozen_string_literal: true

# A cloud file provider
class Provider
  PROVIDERS = {
    0 => 'GoogleDrive'
  }.freeze

  def self.find(id)
    "Providers::#{PROVIDERS[id]}".constantize
  end
end
