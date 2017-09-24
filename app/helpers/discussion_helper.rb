# frozen_string_literal: true

# Define helpers needed in discussion files
module DiscussionHelper
  # The verb to use for 'initiated by' depending on discussion type
  def action_verb_for_initiated_by(discussion)
    case discussion
    when Discussions::Suggestion  then 'suggested by'
    when Discussions::Issue       then 'raised by'
    when Discussions::Question    then 'asked by'
    else                               'initiated by'
    end
  end
end
