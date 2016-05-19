require 'pry'

module HydraDAM
  class StorageProxyClient
    attr_accessor :filename, :host, :port, :store, :cache

    def initialize
      configure
      get_conn
    end

    def status
      # ping storage proxy for current status of @cache/@filename
      response = @connection.get ['/caches', @cache, 'files', @filename].join('/')
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

    #private

    def configure
      # TODO: Probably don't want this to happen every time, maybe once in an initializer?
      config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'storage_proxy.yml'))).result)[Rails.env].with_indifferent_access
      @host = config["host"] if @host.nil?
      @port = config["port"] if @port.nil?
      @store = config["store"] if @store.nil?
      @cache = config["cache"] if @cache.nil?
    end

    def get_conn
      # Setup the connection to storage proxy
      #configure
      @connection = Faraday.new(@host + ':' + @port.to_s)
      @connection
    end

  end
end
