# frozen_string_literal: true

module VersionControl
  # A version controlled file
  class File
    attr_reader :file_collection, :id, :name, :parent_id, :mime_type, :version,
                :path

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

    # Generate the file's metadata path from its file path and whether it is a
    # folder. Adds /.self to any folder
    def self.file_path_to_metadata_path(file_path, is_folder)
      is_folder ? "#{file_path}/.self" : file_path
    end

    # Generate the file path from a file's metadata path
    # Essentially, just remove /.self from any paths that have that ending.
    def self.metadata_path_to_file_path(metadata_path)
      metadata_path.chomp '/.self'
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
      @path             = params[:path]
      @git_oid          = params[:git_oid]
    end

    # Always return modified time in UTC and as Time class
    # This is important because YAML.safe_load (for reading committed files)
    # only supports a very narrow set of classes, Time being one of them.
    def modified_time
      @modified_time&.utc
    end

    # Return true if file is a directory, false otherwise
    def directory?
      self.class.directory_type?(mime_type)
    end

    # The path to the file's metadata file
    def metadata_path
      return nil unless path.present?
      self.class.file_path_to_metadata_path(path, directory?)
    end
  end
end
