require 'rails_helper'
require 'hydradam/file_set_behavior/has_fits'

describe HydraDAM::FileSetBehavior::HasFITS, :requires_fedora do

  subject do
    # An anonymous class that inherits from ActiveFedora::Base
    # and includes the HydraDAM::FileSetBehavior::HasFITS module.
    Class.new(ActiveFedora::Base) do
      include HydraDAM::FileSetBehavior::HasFITS
    end.new
  end

  after(:all) do
    subject.delete rescue nil
  end

  it 'exposes accessors #fits and #fits=' do
    expect(subject).to respond_to :fits
    expect(subject).to respond_to :"fits="
  end

  describe '#fits=' do
    it 'requires an XMLFile' do
      expect{ subject.fits = "this will fail" }.to raise_error ActiveFedora::AssociationTypeMismatch
    end

    it 'accepts a XMLFile' do
      subject.save! # the parent object must be saved before attaching files.
      expect{ subject.fits = XMLFile.new }.to_not raise_error
    end
  end


  describe '#assign_properties_from_fits' do

    context 'when no FITS xml file has yet been attached' do
      it 'raises a MissingFITSFile' do
        expect{ subject.assign_properties_from_fits }.to raise_error HydraDAM::FileSetBehavior::HasFITS::MissingFITSFile
      end
    end

    context 'when a FITS xml file has been attached' do

      let(:fits_file) { File.open('./spec/fixtures/fits/fits_0_8_10.xml') }

      before do
        Hydra::Works::AddFileToFileSet.call(subject, fits_file, :fits)
        subject.assign_properties_from_fits
      end

      it 'assigns values from FITS XML file to RDF properties on the object' do
        expect(subject.filename).to eq "SANY0473.MP4"
      end
    end
  end

  context 'when the including class does not inherit from ActiveFedora::Base' do

    let(:class_with_missing_dependency) do
      # An anonymous class that includes the HydraDAM::FileSetBehavior::HasFITS
      # module but does not inherity from ActiveFedora::Base like it should
      Class.new do
        include HydraDAM::FileSetBehavior::HasFITS
      end
    end

    it 'raises an error' do
      expect{ class_with_missing_dependency }.to raise_error DependsOn::MissingDependencies
    end
  end
end