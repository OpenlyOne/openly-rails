# frozen_string_literal: true

require 'rake'

shared_context 'rake' do
  let(:rake)      { Rake::Application.new }
  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/tasks/#{task_name.split(':').first}" }
  subject(:task)  { rake[task_name] }

  def loaded_files_excluding_current_rake_file
    $LOADED_FEATURES
      .reject { |file| file == Rails.root.join("#{task_path}.rake").to_s }
  end

  # Reenable all rake tasks to allow them being called a second time
  def reenable_all_tasks
    rake.tasks.each(&:reenable)
  end

  before do
    Rake.application = rake
    Rake.application.rake_require(
      task_path, [Rails.root.to_s], loaded_files_excluding_current_rake_file
    )
    if defined? depends_on_task_paths
      depends_on_task_paths.each do |task|
        Rake.application.rake_require(
          task, [Rails.root.to_s], loaded_files_excluding_current_rake_file
        )
      end
    end

    Rake::Task.define_task(:environment)
  end
end
