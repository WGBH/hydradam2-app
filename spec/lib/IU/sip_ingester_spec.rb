require "rails_helper"
require "IU/sip_ingester"


describe IU::SIPIngester do 

  before { subject.path = "spec/fixtures/IU_samples" }

  describe "#ffprobe" do
    
    it "Returns a file object containign ffprobe XML" do

      expect(subject.ffprobe).to be_a File
  
 
   end
	
  end  

  describe "#ffprobe_path" do

    it "Returns the path to ffprobe file" do

      expect(subject.ffprobe_path).to match "spec/fixtures/IU_samples/123456_ffprobe.xml"
    


    end

  end

end



