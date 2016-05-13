require 'pry'

module HydraDAM
  class StorageProxy
    attr_accessor :filename

    def status
      # ping storage proxy for current status of @filename
      # set session with current status
      # redirect back to fileset
    end

    def stage
      # ping storage proxy for current status of @filename
      # if status is not-staged
      #   post a job to stage @filename
      # end
      # set session with current status
      # redirect back to fileset
    end

    def unstage
      # ping storage proxy for current status of @filename
      # if status is staged
      #   post a job to unstage @filename
      # end
      # set session with current status
      # redirect back to fileset
    end

    def fixity
      # ping storage proxy for current status
      # ?
      # set session with current status
      # redirect back to fileset
    end

    def available_actions
      # get current status
      # return list of available actions, with user-friendly labels
    end

    private

    def get_conn
      # Setup the connection to storage proxy
      # Faraday.new('http://localhost:3001')
    end

  end
end
