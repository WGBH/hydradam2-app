require 'rails_helper'
require 'IU/models/file_set'

describe IU::Models::FileSet do
  it 'includes IU::Models::Concerns::FileSetBehavior' do
    expect(described_class.ancestors).to include IU::Models::Concerns::FileSetBehavior
  end
end