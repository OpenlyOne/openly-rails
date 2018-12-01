# frozen_string_literal: true

require 'extensions/henkei/server.rb'

# Start Apache Tika server unless already running
Henkei::Server.start unless Henkei::Server.running?
