require 'rails_helper'

describe FileSet do
  it 'includes Concerns::FileSetBehavior' do
    expect(described_class.ancestors).to include Concerns::FileSetBehavior
  end
end