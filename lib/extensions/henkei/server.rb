# frozen_string_literal: true

# Open3 for spawning the server
require 'open3'
# Net/HTTP for making CURL-like requests to server
require 'net/http'
# Rubygems for Nokogiri (HACK)
require 'rubygems'
# Nokogiri for extracting text from HTML (HACK)
require 'nokogiri'
# Henkei is not really needed but we are building on top of it, so for now, it
# is good to include it
require 'henkei'

class Henkei
  # Run Henkei in server mode
  class Server
    JAR_PATH =
      Rails.root.join('lib', 'extensions', 'henkei', 'tika-server-1.19.1.jar')

    PORT          = 9998
    HOST          = 'localhost'
    CONTENT_PATH  = '/tika'
    META_PATH     = '/meta'

    # Extract plain text from the provided file
    def self.extract_text(file)
      # HACK: extracting text via Apache Tika includes unwanted artefacts, such
      # =>    as bookmarks and images. Use Nokogiri to get text from HTML
      # =>    instead.
      # put_file(
      #   file: file,
      #   path: CONTENT_PATH,
      #   options: { 'Accept': 'text/plain' }
      # )
      Nokogiri::HTML(extract_html(file)).text.gsub(/\n\n\n+/, "\n\n")
    end

    # Extract html from the provided file
    def self.extract_html(file)
      put_file(
        file: file,
        path: CONTENT_PATH,
        options: { 'Accept': 'text/html' }
      )
    end

    # Extract the content type from the provided file
    def self.extract_content_type(file)
      put_file(
        file: file,
        path: "#{META_PATH}/Content-Type",
        options: { 'Accept': 'text/plain' }
      )
    end

    # Start the Apache Tika server
    def self.start
      input, _output, @server_pid = Open3.popen2e(
        java_path,
        '-Djava.awt.headless=true',
        '-jar',
        JAR_PATH.to_s,
        '-spawnChild'
      )
      input.close
    end

    # Stop the Apache Tika server
    def self.stop
      Process.kill('HUP', @server_pid)
    end

    # Return true if the Apache Tika server is running
    def self.running?
      return true if @server_pid.present?

      request = Net::HTTP::Get.new(CONTENT_PATH)
      perform_request(request).code.eql? '200'
    rescue Errno::ECONNREFUSED
      false
    end

    # Provide the path to the Java binary
    # Copied from Henkei
    #
    def self.java_path
      ENV['JAVA_HOME'] ? ENV['JAVA_HOME'] + '/bin/java' : 'java'
    end
    private_class_method :java_path

    def self.put_file(file:, path:, options: {})
      request = Net::HTTP::Put.new(path)
      request.body_stream = file
      options['Transfer-Encoding'] = 'chunked'
      options['Content-Type'] = 'application/octet-stream'
      options.each do |option, value|
        request[option.to_s] = value
      end
      perform_request(request).body
    end
    private_class_method :put_file

    def self.perform_request(request)
      Net::HTTP.new(HOST, PORT).start do |http|
        http.request(request)
      end
    end
    private_class_method :perform_request
  end
end
