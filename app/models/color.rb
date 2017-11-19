# frozen_string_literal: true

# Class for handling color related logic
class Color
  class << self
    # define available color schemes
    def schemes
      # [
      #   { base: 'red',          text: 'white' },
      #   { base: 'amber',        text: 'black' },
      #   { base: 'yellow',       text: 'black' },
      #   { base: 'light-green',  text: 'black' },
      #   { base: 'light-blue',   text: 'white' },
      #   { base: 'indigo',       text: 'white' },
      #   { base: 'purple',       text: 'white' }
      # ]
      [
        { base: 'indigo', text: 'white' }
      ]
    end
  end
end
