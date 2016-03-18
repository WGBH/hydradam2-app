require 'rails_helper'
require 'WGBH/models/concerns/file_set_behavior'


describe WGBH::Models::Concerns::FileSetBehavior do

  before do
    # Create a TestClass that includes our module
    class TestFileSet < ActiveFedora::Base
      include WGBH::Models::Concerns::FileSetBehavior
    end
  end

  after do
    # destroy our TestClass
    Object.send(:remove_const, :TestFileSet)
  end

  it 'includes HydraDAM::FileSetBehavior::HasFITS' do
    expect(TestFileSet.ancestors).to include HydraDAM::FileSetBehavior::HasFITS
  end
end