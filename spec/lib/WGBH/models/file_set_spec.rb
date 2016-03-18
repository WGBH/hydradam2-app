require 'rails_helper'
require 'WGBH/models/file_set'


describe WGBH::Models::FileSet do
  it 'includes WGBH::Models::Concerns::FileSetBehavior' do
    expect(described_class.ancestors).to include WGBH::Models::Concerns::FileSetBehavior
  end
end