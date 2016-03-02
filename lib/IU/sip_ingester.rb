module IU
  
  class SIPIngester

    attr_accessor :path
    
    def ffprobe
      
      File.new(ffprobe_path)
      


    end

    def ffprobe_path

        
      Dir["#{path}/*ffprobe*"].first

    end

  end

end
