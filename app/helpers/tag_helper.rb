# frozen_string_literal: true

# Define helpers needed for tags
module TagHelper
  # Convert a tag to tag case
  # In tag case, the first character of every word is upcased. All remaining
  # characters remain untouched
  def tag_case(tag)
    tag.gsub(/\w+/, &:upcase_first)
  end
end
