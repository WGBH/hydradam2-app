require 'rails_helper'
require 'hydradam/file_set_behavior/has_memnon'

describe HydraDAM::FileSetBehavior::Hasmemnon, :requires_fedora do

  subject do
    # An anonymous class that inherits from ActiveFedora::Base
    # and includes the HydraDAM::FileSetBehavior::Hasmemnon module.
    Class.new(ActiveFedora::Base) do
      include HydraDAM::FileSetBehavior::Hasmemnon
    end.new
  end

  after(:all) do
    subject.delete rescue nil
  end

  it 'exposes accessors #memnon and #memnon=' do
    expect(subject).to respond_to :memnon
    expect(subject).to respond_to :"memnon="
  end

  describe '#memnon=' do
    it 'requires an XMLFile' do
      expect{ subject.memnon = "this will fail" }.to raise_error
    end

    it 'accepts a XMLFile' do
      subject.save! # the parent object must be saved before attaching files.
      expect{ subject.memnon = XMLFile.new }.to_not raise_error
    end
  end


  describe '#assign_properties_from_memnon' do

    context 'when no memnon xml file has yet been attached' do
      it 'raises a MissingmemnonFile' do
        expect{ subject.assign_properties_from_memnon }.to raise_error HydraDAM::FileSetBehavior::Hasmemnon::MissingmemnonFile
      end
    end

    context 'when a memnon xml file has been attached' do

      let(:memnon_file) { File.open('./spec/fixtures/memnon/MDPI_manifest_40000000523896X.xml') }

      before do
        Hydra::Works::AddFileToFileSet.call(subject, memnon_file, :memnon)
        subject.assign_properties_from_memnon
      end

      it 'assigns values from memnon XML file to RDF properties on the object' do
        expect(subject.filename).to eq "SANY0473.MP4"
      end
    end
  end

  context 'when the including class does not inherit from ActiveFedora::Base' do

    let(:class_with_missing_dependency) do
      # An anonymous class that includes the HydraDAM::FileSetBehavior::Hasmemnon
      # module but does not inherity from ActiveFedora::Base like it should
      Class.new do
        include HydraDAM::FileSetBehavior::Hasmemnon
      end
    end

    it 'raises an error' do
      expect{ class_with_missing_dependency }.to raise_error DependsOn::MissingDependencies
    end
  end
end
