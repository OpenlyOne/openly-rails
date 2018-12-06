# frozen_string_literal: true

module VCS
  module Operations
    # Diffs two contents
    class ContentDiffer
      attr_accessor :new_content, :old_content

      # Use backspace as word delimiter because this character will
      # probably never show up in any of our content
      # TODO: Verify that this is true!
      WORD_DELIMITER = "\b"

      # Run dwdiff against the given content and remove delimiters
      def self.change(new_content, old_content)
        remove_delimiters(
          dwdiff(
            escape(new_content),
            escape(old_content)
          )
        )
      end

      # Run shell dwdiff with the two contents, using {--} and {++}
      # delimiters to mark changes and the .word_delimiter as word boundary
      # Content must be escaped, otherwise user input will be indistinguishable
      # from dwdiff formatting
      def self.dwdiff(escaped_new_content, escaped_old_content)
        # dwdiff requires files to work, so let's transform content into
        # tempfiles
        file_for_new_content = tempfile(escaped_new_content)
        file_for_old_content = tempfile(escaped_old_content)

        begin
          `dwdiff \
          #{file_for_old_content.path} #{file_for_new_content.path} \
          -w \{-- -x --\} -y \{++ -z ++\} --white-space="#{word_delimiter}"`
        ensure
          # Close tempfiles
          file_for_new_content.close!
          file_for_old_content.close!
        end
      end

      # Escape the given content:
      # Escapes + and - symbols (so we can distinguish user input from diff)
      # Escapes whitespace characters by wrapping them in word delimiters, so
      # that individual whitespace characters appear in diff
      def self.escape(content)
        content
          .gsub(
            /(?<symbol>[-\+])/,
            '\\\\\k<symbol>'
          ).gsub(
            /(?<whitespace>[^\S])/,
            "#{word_delimiter}\\k<whitespace>#{word_delimiter}"
          )
      end

      def self.unescape(content)
        content.gsub(/\\(?<symbol>[-\+])/, '\k<symbol>')
      end

      # Removes delimiters from the content
      def self.remove_delimiters(content)
        content.remove(word_delimiter)
      end

      def self.tempfile(content)
        Tempfile.new.tap do |file|
          file.write(content)
          file.flush
        end
      end

      # The character that separates one word or character from another.
      # Indicates the word boundary for diffing.
      def self.word_delimiter
        WORD_DELIMITER
      end

      def initialize(new_content:, old_content:)
        self.new_content = new_content
        self.old_content = old_content
      end

      # Return the full change/diff
      def full
        @full ||= self.class.change(new_content, old_content)
      end

      # Return the full change broken into fragments and aggregated across
      # individual white space characters
      def fragments
        @fragments ||=
          VCS::Operations::ContentChangeFragment.fragment_and_aggregate(full)
      end
    end
  end
end
