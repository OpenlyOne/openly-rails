# frozen_string_literal: true

module VersionControl
  # A version controlled file
  class File
    attr_reader :file_collection, :id, :name, :parent_id, :mime_type, :version,
                :modified_time
    delegate :lock, :repository, to: :@file_collection

    # Initialize an instance of version controlled file and cast to appropriate
    # type (staged or committed)
    def self.new(file_collection, params)
      return super unless self == VersionControl::File

      case file_collection
      when VersionControl::FileCollections::Staged
        Files::Staged.new(file_collection, params)
      else
        raise(ActiveRecord::TypeConflictError,
              "Type #{file_collection} is not supported.")
      end
    end

    # Return true if mime_type refers to a directory, such as
    # 'application/vnd.google-apps.folder'
    def self.directory_type?(mime_type)
      mime_type == 'application/vnd.google-apps.folder'
    end

    # Initialize the instance
    def initialize(file_collection, params)
      @file_collection  = file_collection
      @id               = params[:id]
      @name             = params[:name]
      @parent_id        = params[:parent_id]
      @mime_type        = params[:mime_type]
      @version          = params[:version]
      @modified_time    = params[:modified_time]
    end

    # Return true if file is a directory, false otherwise
    def directory?
      self.class.directory_type?(mime_type)
    end
  end
end
