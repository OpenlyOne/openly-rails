# frozen_string_literal: true

class Notification
  # Select source for the notifying object
  class Source
    def self.for_revision(revision)
      revision.author
    end
  end
end
