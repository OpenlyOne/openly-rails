# frozen_string_literal: true

module VCS
  module Operations
    # A fragment of a content change
    # A fragment is either an addition, deletion, or unchanged text
    class ContentChangeFragment
      attr_accessor :content, :is_first, :is_last

      class << self
        delegate :unescape, to: :'VCS::Operations::ContentDiffer'
      end

      # A fragment that has been added to new content
      class Addition < VCS::Operations::ContentChangeFragment
        def addition?
          true
        end

        def type
          :addition
        end
      end

      # A fragment that has been deleted from old content
      class Deletion < VCS::Operations::ContentChangeFragment
        def deletion?
          true
        end

        def type
          :deletion
        end
      end

      # A fragment that has been retained from old to new content
      class Retain < VCS::Operations::ContentChangeFragment
        # Truncate the content to the number of characters
        # TODO: Truncate to whole words only
        # TODO: Break out into three methods: truncate_beginning,
        # =>    truncate_ending, truncate_beginning_and_ending
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

        def beginning?
          is_first
        end

        def ending?
          is_last
        end

        def middle?
          !is_first && !is_last
        end

        def retain?
          true
        end

        def type
          %i[beginning middle ending].find do |change|
            send("#{change}?")
          end
        end
      end

      # Break apart the content change string into its fragments
      def self.fragment(content_change)
        fragments = content_change.split(/(\{[-\+]{2}.*?[-\+]{2}\})/m)
        fragments.delete_if(&:blank?)

        fragments.each_with_index.map do |fragment, index|
          klass_for_fragment(fragment).new(
            content: parse_raw_content(fragment),
            is_first: index.zero?,
            is_last: (index == fragments.length - 1)
          )
        end
      end

      def self.klass_for_fragment(raw_content)
        return Addition if raw_content.start_with?('{++')

        return Deletion if raw_content.start_with?('{--')

        Retain
      end

      def self.parse_raw_content(raw_content)
        unescape(
          raw_content.gsub(
            /^\{((\+\+)|(--))(?<content>.*?)((\+\+)|(--))\}$/m,
            '\k<content>'
          )
        )
      end

      def initialize(content:, is_first: false, is_last: false)
        self.content = content
        self.is_first = is_first
        self.is_last = is_last
      end

      def addition?
        false
      end

      def deletion?
        false
      end

      def retain?
        false
      end
    end
  end
end
