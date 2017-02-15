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
      Rails.logger.info 'Doing GET of ' + @host + ':' + @port.to_s + [@api_prefix,@cache_path, @cache, @cache_files_path, filename].join('/')
      connection.get [@api_prefix,@cache_path, @cache, @cache_files_path, filename].join('/')

    end

    def stage(filename)
      Rails.logger.info 'Doing POST to ' + @host + ':' + @port.to_s + [@api_prefix,'jobs', @cache, filename, 'stage'].join('/')
      connection.post do |req|
        req.url [@api_prefix,'jobs', @cache, filename, 'stage'].join('/')
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def unstage(filename)
      Rails.logger.info 'Doing POST to ' + @host + ':' + @port.to_s + [@api_prefix,'jobs', @cache, filename, 'unstage'].join('/')
      connection.post do |req|
        req.url [@api_prefix,'jobs', @cache, filename, 'unstage'].join('/')
        req.headers['Content-Type'] = 'application/json'
      end
    end

    def fixity(filename, fixity_type = 'md5')
      # POST a job to initiate a fixity check on filename. fixity_type optional but defaults to md5
      Rails.logger.info 'Doing POST to ' + @host + ':' + @port.to_s + [@api_prefix,'jobs', @cache, filename, 'fixity'].join('/')
      connection.post do |req|
        req.url [@api_prefix,'jobs', @cache, filename, 'fixity'].join('/')
        req.headers['Content-Type'] = 'application/json'
      end
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
