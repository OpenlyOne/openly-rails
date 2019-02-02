# frozen_string_literal: true

RSpec.describe Profiles::UserDashboard, type: :model do
  subject(:dashboard) { described_class }
  let(:attributes)    { dashboard::ATTRIBUTE_TYPES }
  let(:resource)      { Profiles::User }

  describe 'attribute types' do
    it 'only allows search in attributes that exist in the database' do
      searchable_attributes = attributes.select do |_key, value|
        value.searchable?
      end.keys
      attributes_in_database = resource.columns.map(&:name).map(&:to_sym)

      expect(attributes_in_database).to include(*searchable_attributes)
    end
  end
end
