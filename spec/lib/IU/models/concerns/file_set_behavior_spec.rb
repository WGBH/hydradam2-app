require 'rails_helper'
require 'IU/models/concerns/file_set_behavior'


describe IU::Models::Concerns::FileSetBehavior do

  before do
    class TestClass < ActiveFedora::Base
      include IU::Models::Concerns::FileSetBehavior
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
  end

  it 'includes HydraDAM::FileSetBehavior::HasFfprobe' do
    expect(TestClass.ancestors).to include HydraDAM::FileSetBehavior::HasFfprobe
  end
end