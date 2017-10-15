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

  # The color scheme to render depending on discussion type
  def color_scheme_for_discussion(discussion)
    case discussion
    when Discussions::Suggestion  then 'green white-text'
    when Discussions::Issue       then 'red white-text'
    when Discussions::Question    then 'blue white-text'
    end
  end

  # The icon (SVG) to render depending on discussion type
  # rubocop:disable Metrics/MethodLength
  def icon_path_for_discussion(discussion)
    case discussion
    when Discussions::Suggestion # plus-circle
      'M17,13H13V17H11V13H7V11H11V7H13V11H17M12,2A10,10 0 0,0 2,12A10,10 0 0,' \
      '0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2Z'
    when Discussions::Issue # alert-circle
      'M13,13H11V7H13M13,17H11V15H13M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,' \
      '22A10,10 0 0,0 22,12A10,10 0 0,0 12,2Z'
    when Discussions::Question # help-circle
      'M15.07,11.25L14.17,12.17C13.45,12.89 13,13.5 13,15H11V14.5C11,13.39 ' \
      '11.45,12.39 12.17,11.67L13.41,10.41C13.78,10.05 14,9.55 14,9C14,7.89 ' \
      '13.1,7 12,7A2,2 0 0,0 10,9H8A4,4 0 0,1 12,5A4,4 0 0,1 16,9C16,9.88 ' \
      '15.64,10.67 15.07,11.25M13,19H11V17H13M12,2A10,10 0 0,0 2,12A10,10 0 0' \
      ',0 12,22A10,10 0 0,0 22,12C22,6.47 17.5,2 12,2Z'
    end
    # rubocop:enable Metrics/MethodLength
  end
end
