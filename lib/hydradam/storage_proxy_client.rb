require 'pry'

module HydraDAM
  class StorageProxyClient
    attr_accessor :host, :port, :store, :cache, :api_prefix,
                  :store_path, :store_files_path, :cache_path, :cache_files_path

    def initialize
      configure
      disable if @enabled == false or @enabled.nil?
      enable if @enabled == true
    end

    def enable
      @enabled_state = true
    end

    def disable
      @enabled_state = false
    end

    def enabled?
      @enabled_state
    end

    def status(filename)
      # ping storage proxy for current status of @cache/@filename
      connection.get [@api_prefix,@cache_path, @cache, @cache_files_path, filename].join('/')
    end

    def stage(filename)
      # ping storage proxy for current status of @filename
      connection.post [@api_prefix,'jobs', @cache, filename].join('/'), :type => 'stage'
      # if status is not-staged
      #   post a job to stage @filename
      # end
    end

    def unstage(filename)
      # ping storage proxy for current status of @filename
      connection.post [@api_prefix,'jobs', @cache, filename].join('/'), :type => 'unstage'
      # if status is staged
      #   post a job to unstage @filename
      # end
    end

    def fixity(filename)
      # ping storage proxy for current status
      connection.post [@api_prefix,'jobs', @cache, filename].join('/'), :type => 'fixity'
    end

    def available_actions
      # get current status
      # return list of available actions, with user-friendly labels
    end

    #private

    def configure
      # TODO: Probably don't want this to happen every time, maybe once in an initializer?
      config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'storage_proxy.yml'))).result)[Rails.env].with_indifferent_access
      @enabled = config["enabled"]
      @host = config["host"] if @host.nil?
      @port = config["port"] if @port.nil?
      @store = config["store"] if @store.nil?
      @cache = config["cache"] if @cache.nil?
      @api_prefix = config["api_prefix"] if @api_prefix.nil?
      @store_path = config["store_path"] if @store_path.nil?
      @store_files_path = config["store_files_path"] if @store_files_path.nil?
      @cache_path = config["cache_path"] if @cache_path.nil?
      @cache_files_path = config["cache_files_path"] if @cache_files_path.nil?
    end

    def connection
      @connection ||= Faraday.new(@host + ':' + @port.to_s)
    end


  end
end
