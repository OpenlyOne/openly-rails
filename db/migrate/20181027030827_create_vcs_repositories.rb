# frozen_string_literal: true

class CreateVcsRepositories < ActiveRecord::Migration[5.2]
  def change
    create_table(:vcs_repositories, &:timestamps)
  end
end
