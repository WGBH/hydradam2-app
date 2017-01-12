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

  it 'exposes accessors #exif and #exif=' do
    expect(subject).to respond_to :exif
    expect(subject).to respond_to :"exif="
  end

  describe '#exif=' do
    it 'requires an XMLFile' do
      expect{ subject.exif = "this will fail" }.to raise_error ActiveFedora::AssociationTypeMismatch
    end

    it 'accepts a XMLFile' do
      subject.save! # the parent object must be saved before attaching files.
      expect{ subject.exif = XMLFile.new }.to_not raise_error
    end
  end


  describe '#assign_properties_from_exif' do

    let(:exif_file) { File.open('./spec/fixtures/exiftool/exiftool_9_94.xml') }

    before do
      Hydra::Works::AddFileToFileSet.call(subject, exif_file, :exif)
      subject.assign_properties_from_exif
    end

    it 'assigns values from EXIF XML file to RDF properties on the object' do
      expect(subject.filename).to eq "2 Schuman_a.aiff"
    end
  end

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
