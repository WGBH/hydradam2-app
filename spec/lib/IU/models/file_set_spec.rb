require 'rails_helper'

describe FileSet do
  it 'includes IU::Models::Concerns::FileSetBehavior' do
    expect(described_class.ancestors).to include IU::Models::Concerns::FileSetBehavior
  end
end