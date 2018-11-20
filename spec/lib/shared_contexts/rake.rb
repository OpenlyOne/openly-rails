# frozen_string_literal: true

require 'rake'

shared_context 'rake' do
  subject(:task) { Rake.application[task_name] }

  # The name of the task can be derived from the name of the spec
  let(:task_name) { self.class.top_level_description }
  # Specify additional tasks to load upon which the main task depends
  let(:tasks_to_load) { [] }

  # Helper method for loading paths
  def loaded_files_excluding(path)
    $LOADED_FEATURES
      .reject { |file| file == Rails.root.join("#{path}.rake").to_s }
  end

  # Reenable all rake tasks to allow them being called a second time
  def reenable_all_tasks
    Rake.application.tasks.each(&:reenable)
  end

  # The path to a task
  def path_to_task(task_name)
    "lib/tasks/#{task_name.to_s.tr(':', '/')}"
  end

  before do
    Rake.application ||= Rake::Application.new

    # Load each task if not yet defined
    ([task_name] + tasks_to_load).each do |task|
      next if Rake::Task.task_defined?(task)

      path = path_to_task(task)

      Rake.application.rake_require(
        path, [Rails.root.to_s], loaded_files_excluding(path)
      )
    end

    # Allow all tasks to be called
    reenable_all_tasks

    # Define default environment task because it is needed by almost every
    # Rake task
    next if Rake::Task.task_defined?(:environment)

    Rake::Task.define_task(:environment)
  end
end
