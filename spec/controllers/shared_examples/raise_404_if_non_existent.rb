# frozen_string_literal: true

# Expect ActiveRecord::RecordNotFound error (404) when object does not exist
RSpec.shared_examples 'raise 404 if non-existent' do |object|
  let(:object_class) { object }
  before { object_class&.destroy_all }

  it "raises 404 when #{object.to_s.downcase} does not exist" do
    expect { run_request }.to raise_error ActiveRecord::RecordNotFound
  end
end
