# frozen_string_literal: true

module VCS
  module Operations
    # A fragment of a content change
    # A fragment is either an addition, deletion, or unchanged text
    class ContentChangeFragment
      attr_accessor :fragment, :is_first, :is_last

      class << self
        delegate :unescape, to: :'VCS::Operations::ContentDiffer'
      end

      # Break apart the content change string into its fragments
      def self.fragment(content_change)
        fragments = content_change.split(/(\{[-\+]{2}.*?[-\+]{2}\})/m)
        fragments.delete_if(&:blank?)

        fragments.each_with_index.map do |fragment, index|
          new(
            fragment,
            is_first: index.zero?,
            is_last: (index == fragments.length - 1)
          )
        end
      end

      def initialize(fragment, is_first: false, is_last: false)
        self.fragment = fragment
        self.is_first = is_first
        self.is_last = is_last
      end

      # Return the unescaped content of the fragment, removing any delimiters
      def content
        self.class.unescape(
          fragment.gsub(
            /^\{((\+\+)|(--))(?<content>.*?)((\+\+)|(--))\}$/m,
            '\k<content>'
          )
        )
      end

      # Truncate the content to the number of characters
      # TODO: Truncate to whole words only
      # TODO: Break out into three methods: truncate_beginning, truncate_ending,
      # =>    truncate_beginning_and_ending
      def truncated_content(num_chars)
        if beginning?
          content.gsub(/^.*(?<to_show>.{#{num_chars}})$/m, '...\k<to_show>')
        elsif ending?
          content.gsub(/^(?<to_show>.{#{num_chars}}).*$/m, '\k<to_show>...')
        elsif middle?
          content.gsub(
            /^(?<beginning>.{#{num_chars}}).*(?<ending>.{#{num_chars}})$/m,
            '\k<beginning>...\k<ending>'
          )
        end
      end

      def addition?
        fragment.start_with?('{++')
      end

      def beginning?
        no_change? && is_first
      end

      def deletion?
        fragment.start_with?('{--')
      end

      def ending?
        no_change? && is_last
      end

      def middle?
        no_change? && !is_first && !is_last
      end

      def no_change?
        !addition? && !deletion?
      end

      def type
        %i[beginning middle ending addition deletion].select do |change|
          send("#{change}?")
        end
      end
    end
  end
end
