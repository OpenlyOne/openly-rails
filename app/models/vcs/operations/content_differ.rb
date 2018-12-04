# frozen_string_literal: true

module VCS
  module Operations
    # Diffs two contents
    class ContentDiffer
      attr_accessor :new_content, :old_content

      # Run shell dwdiff with the two contents and using {--} and {++}
      # delimiters to mark changes
      def self.change(new_content, old_content)
        # dwdiff requires files to work, so let's transform content into
        # tempfiles
        file_for_new_content = tempfile(escape(new_content))
        file_for_old_content = tempfile(escape(old_content))

        begin
          `dwdiff \
          #{file_for_old_content.path} #{file_for_new_content.path} \
          -w \{-- -x --\} -y \{++ -z ++\}`
        ensure
          # Close tempfiles
          file_for_new_content.close!
          file_for_old_content.close!
        end
      end

      def self.escape(content)
        content.gsub(/(?<symbol>[-\+])/, '\\\\\k<symbol>')
      end

      def self.unescape(content)
        content.gsub(/\\(?<symbol>[-\+])/, '\k<symbol>')
      end

      def self.tempfile(content)
        Tempfile.new.tap do |file|
          file.write(content)
          file.flush
        end
      end

      def initialize(new_content:, old_content:)
        self.new_content = new_content
        self.old_content = old_content
      end

      # Return the full change/diff
      def full
        @full ||=
          self.class.change(new_content, old_content)
      end

      def fragments
        @fragments ||= VCS::Operations::ContentChangeFragment.fragment(full)
      end
    end
  end
end
