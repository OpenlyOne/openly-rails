# frozen_string_literal: true

desc 'Performance: Copy files'
# rubocop:disable Metrics/BlockLength
namespace :performance do
  task copy_files: :environment do
    connection = Providers::GoogleDrive::ApiConnection.default
    drive_service = connection.instance_variable_get(:@drive_service)

    source_folder_id = '1-93WT5q7UbzirOr-xow-Fo4hQZ1_3bXp'
    target_folder_id = '1MQjbCuXiZ6vCnB2Y9ZjAHSbRXsHBJlFX'
    target_folder = Google::Apis::DriveV3::File.new(parents: [target_folder_id])

    # Fetch all items (files & folders) in source folder
    files = connection.find_files_by_parent_id(source_folder_id)
    # Aggregate file IDs (reject folders)
    file_ids = files.reject do |file|
      file.mime_type == Providers::GoogleDrive::MimeType.folder
    end.map(&:id)

    puts "Benchmarking copying files with #{file_ids.count} records"
    statuses = []
    time = Benchmark.realtime do
      threads = []
      # start 10 threads, each copying an equal share of the files
      # source: http://heyrod.com/snippets/split-ruby-array-equally.html
      file_ids.a.each_slice((a.size / 10.to_f).round).to_a do |file_ids_slice|
        threads << Thread.new do
          # execute copying as batch request
          drive_service.batch do |request|
            file_ids_slice.each do |id|
              request.copy_file(id, target_folder) do |_file, status|
                # store status
                statuses << status
              end
            end
          end
        end
      end
      threads.map(&:join)
    end
    puts "Completed in #{time} seconds"
    puts statuses
  end
end
# rubocop:enable Metrics/BlockLength
