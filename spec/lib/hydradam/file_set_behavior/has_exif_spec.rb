require 'rails_helper'
require 'hydradam/file_set_behavior/has_exif'

describe HydraDAM::FileSetBehavior::HasEXIF, :requires_fedora do

  subject do
    # An anonymous class that inherits from ActiveFedora::Base
    # and includes the HydraDAM::FileSetBehavior::HasFITS module.
    Class.new(ActiveFedora::Base) do
      include HydraDAM::FileSetBehavior::HasEXIF
    end.new
  end

  after(:all) do
    subject.delete rescue nil
  end

# it 'exposes accessors #exif and #exif=' do
#    expect(subject).to respond_to :exif
#    expect(subject).to respond_to :"exif="
#  end
  
  context 'when the including class does not inherit from ActiveFedora::Base' do

    let(:class_with_missing_dependency) do
      # An anonymous class that includes the HydraDAM::FileSetBehavior::HasEXIF
      # module but does not inherity from ActiveFedora::Base like it should
      Class.new do
        include HydraDAM::FileSetBehavior::HasEXIF
      end
    end

    it 'raises an error' do
      expect{ class_with_missing_dependency }.to raise_error DependsOn::MissingDependencies
    end
  end
end
