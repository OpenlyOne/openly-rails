# frozen_string_literal: true

# Class for handling color related logic
class Color
  ACCENTS = %w[accent-1 accent-2 accent-3 accent-4].freeze
  SHADES  = %w[lighten-5 lighten-4 lighten-3 lighten-2 lighten-1
               base darken-1 darken-2 darken-3 darken-4].freeze
  # At what shade / accent level does the font color switch from black to white
  # shade: 1 is lighten-4, shade: 5 is base, shade: 9 is darken-4
  # accent: 1 is accent-1, accent: 4 is accent-4
  # shade values of 10 and accent values of 5 indicate that font is always black
  # Breakpoints taken from https://material.io/color/
  FONT_COLOR_BREAK_POINTS = {
    red:            { shade: 7,   accent: 4 },
    pink:           { shade: 6,   accent: 4 },
    purple:         { shade: 4,   accent: 4 },
    'deep-purple':  { shade: 4,   accent: 2 },
    indigo:         { shade: 4,   accent: 2 },
    blue:           { shade: 7,   accent: 3 },
    'light-blue':   { shade: 8,   accent: 4 },
    cyan:           { shade: 8,   accent: 5 },
    teal:           { shade: 7,   accent: 5 },
    green:          { shade: 8,   accent: 5 },
    'light-green':  { shade: 9,   accent: 5 },
    lime:           { shade: 9,   accent: 5 },
    yellow:         { shade: 10,  accent: 5 },
    amber:          { shade: 10,  accent: 5 },
    orange:         { shade: 10,  accent: 5 },
    'deep-orange':  { shade: 9,   accent: 4 },
    brown:          { shade: 4              },
    gray:           { shade: 6              },
    'blue-gray':    { shade: 6              },
    black:          { shade: 0              },
    white:          { shade: 10             }
  }.freeze

  class << self
    # Return the preferred font color for the given color_scheme (based on
    # which color will result in the higher contrast)
    def font_color_for(color_scheme)
      base, modifier = color_scheme.split(' ')
      modifier_type = modifier.starts_with?('accent') ? :accent : :shade

      # convert modifier to scale of 1 - 9 (1-4 for accent colors)
      darkness = modifier_to_darkness(modifier)

      # check if darkness level exceeds breaking point
      if darkness >= self::FONT_COLOR_BREAK_POINTS[base.to_sym][modifier_type]
        'white-text'
      else
        'black-text'
      end
    end

    # Return the color options as a flattened array of strings:
    # ['red base', 'red lighten-1', 'blue base', 'green base', ...]
    def options
      @options ||=
        base_colors.flat_map do |color|
          modifiers_for(color).map { |modifier| "#{color} #{modifier}" }
        end
    end

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
        { base: 'blue', text: 'white' }
      ]
    end

    private

    # Return the available base colors (red, yellow, green, indigo, ...)
    def base_colors
      self::FONT_COLOR_BREAK_POINTS.keys.map(&:to_s)
    end

    # Return the available modifiers for a given color
    def modifiers_for(color)
      case color.to_s
      when 'black', 'white'
        # only base shade
        %w[base]
      when 'brown', 'gray', 'blue-gray'
        # only shades
        self::SHADES
      else
        # shades and accents
        self::SHADES + self::ACCENTS
      end
    end

    # Return the modifier converted to a darkness value of 0-9 (shade) or
    # 1-4 (accent)
    def modifier_to_darkness(modifier)
      case modifier.split('-')[0]
      when 'lighten'
        5 - modifier.split('-')[1].to_i
      when 'base'
        5
      when 'darken'
        5 + modifier.split('-')[1].to_i
      when 'accent'
        modifier.split('-')[1].to_i
      end
    end
  end
end
