require "rails_helper"
require "IU/sip_ingester"

describe IU::SIPIngester do 


  describe '#initialize' do
    it 'requires :path option' do
      expect{ IU::SIPIngester.new(depositor: "foo") }.to raise_error ArgumentError, "Missing required option :path"
    end

    it 'requires :depositor option' do
      expect{ IU::SIPIngester.new(path: "foo") }.to raise_error ArgumentError, "Missing required option :depositor"
    end
  end

  describe "#ffprobe" do
    it "Returns a file object containing ffprobe XML" do
      expect(subject.ffprobe).to be_a File
    end
  end

  describe '#ingested_objects' do
    context 'before calling #run!' do
      it 'returns an empty array' do
        ingester = IU::FfprobeBatchIngester.new
        expect(ingester.ingested_objects).to be_empty
      end
    end
  end



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
end



