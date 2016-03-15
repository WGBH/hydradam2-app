require "rails_helper"
require "IU/sip_ingester"

describe IU::SIPIngester do 

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Half finished IU ingest code.. work in progress.
  let(:test_user) { User.new(email: 'test@hydradam.org', guest: false) }

  let(:subject) { IU::SIPIngester.new(path: 'spec/fixtures/MDPI-SIP-package', depositor: test_user) }

<<<<<<< HEAD

  describe '#initialize' do
    it 'requires :path option' do
      expect{ IU::SIPIngester.new(depositor: "foo") }.to raise_error ArgumentError, "Missing required option :path"
    end

    it 'requires :depositor option' do
      expect{ IU::SIPIngester.new(path: "foo") }.to raise_error ArgumentError, "Missing required option :depositor"
    end
  end

  describe "#mezzanine_ffprobe_path" do
    it "returns the path to ffprobe file for the mezzanine" do
      expect(File.basename(subject.mezzanine_ffprobe_path)).to match "MDPI_40000000788093_01_access_ffprobe.xml"
    end
  end

  describe "#access_copy_ffprobe_path" do
    it "returns the path to ffprobe file for the access copy" do
      expect(File.basename(subject.ffprobe_path)).to match "MDPI_40000000788093_01_mezz_ffprobe.xml"
    end
  end

  # def each_is_a?(objects, class_or_module)
  #   objects.map{|obj| obj.is_a? class_or_module }.all?
  # end

  # def each_has_been_persisted?(objects)
  #   objects.map {|obj| obj.persisted? }.all?    
  # end

  # it 'returns the same number of objects as files in the batch' do
  #   expect(@ingester.ingested_objects,count)
  # end
=======
=======
>>>>>>> Half finished IU ingest code.. work in progress.

  describe '#initialize' do
    it 'requires :path option' do
      expect{ IU::SIPIngester.new(depositor: "foo") }.to raise_error ArgumentError, "Missing required option :path"
    end

    it 'requires :depositor option' do
      expect{ IU::SIPIngester.new(path: "foo") }.to raise_error ArgumentError, "Missing required option :depositor"
    end
  end

  describe "#mezzanine_ffprobe_path" do
    it "returns the path to ffprobe file for the mezzanine" do
      expect(File.basename(subject.mezzanine_ffprobe_path)).to match "MDPI_40000000788093_01_access_ffprobe.xml"
    end
  end

  describe "#access_copy_ffprobe_path" do
    it "returns the path to ffprobe file for the access copy" do
      expect(File.basename(subject.ffprobe_path)).to match "MDPI_40000000788093_01_mezz_ffprobe.xml"
    end
  end

  # def each_is_a?(objects, class_or_module)
  #   objects.map{|obj| obj.is_a? class_or_module }.all?
  # end

  # def each_has_been_persisted?(objects)
  #   objects.map {|obj| obj.persisted? }.all?    
  # end

<<<<<<< HEAD
  describe "#ffprobe_path" do
    it "Returns the path to ffprobe file" do
      expect(subject.ffprobe_path).to match "spec/fixtures/IU_samples/123456_ffprobe.xml"
    end
  end

  def each_is_a?(objects, class_or_module)
    objects.map{|obj| obj.is_a? class_or_module }.all?
  end

  def each_has_been_persisted?(objects)
    objects.map {|obj| obj.persisted? }.all?    
  end

  it 'returns the same number of objects as files in the batch' do
    expect(@ingester.ingested_objects,count)
  end
>>>>>>> Adds parameter checking
=======
  # it 'returns the same number of objects as files in the batch' do
  #   expect(@ingester.ingested_objects,count)
  # end
>>>>>>> Half finished IU ingest code.. work in progress.
end
