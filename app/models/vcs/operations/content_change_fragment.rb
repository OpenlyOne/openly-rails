# frozen_string_literal: true

module VCS
  module Operations
    # A fragment of a content change
    # A fragment is either an addition, deletion, or unchanged text
    class ContentChangeFragment
      attr_accessor :content, :is_first, :is_last

      # Regex for a paragraph break
      PARAGRAPH_BREAK = /\n(?:\n)+/

      class << self
        delegate :unescape, :word_delimiter,
                 to: :'VCS::Operations::ContentDiffer'
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

      # Aggregrate changes across individual whitespace (combine multiple
      # changes into one to improve readability)
      def self.aggregate(fragments)
        groups = fragments.split_with_delimiter { |f| f.retain? && !f.space? }

        groups.flat_map do |group|
          # Skip this group unless it includes both additions and deletions
          next group unless group.any?(&:addition?) && group.any?(&:deletion?)

          [Deletion.merge(group.reject(&:addition?)),
           Addition.merge(group.reject(&:deletion?))]
        end
      end

      # Break apart the content change string into its fragments
      def self.fragment(content_change)
        fragments = content_change.split(/(\{[-\+]{2}.*?[-\+]{2}\})/m)
        fragments.delete_if(&:empty?)

        fragments.each_with_index.map do |fragment, index|
          klass_for_fragment(fragment).new(
            content: parse_raw_content(fragment),
            is_first: index.zero?,
            is_last: (index == fragments.length - 1)
          )
        end
      end

      # Break apart the content change string into its fragments and aggregate
      # related changes
      def self.fragment_and_aggregate(content_change)
        aggregate(fragment(content_change))
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

      # Merge the provided fragment contents into a single fragment
      def self.merge(fragments)
        new(content: fragments.map(&:content).join)
      end

      def initialize(content:, is_first: false, is_last: false)
        self.content = content
        self.is_first = is_first
        self.is_last = is_last
      end

      def break_into_paragraphs
        content.split(/(#{PARAGRAPH_BREAK})/).map do |paragraph|
          next if paragraph.empty?

          self.class.new(content: paragraph)
        end.compact
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

      def paragraph_break?
        content.match?(/^#{PARAGRAPH_BREAK}$/)
      end

      # Is this fragment a single whitespace?
      def space?
        content.eql?(' ')
      end
    end
  end
end
