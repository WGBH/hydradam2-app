module StorageControllerBehavior
  require 'hydradam/storage_proxy_client'

  def show
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    @file_status_resp = get_file_status
    if params[:next_action] == 'file_status'
      @file_status_resp = get_file_status
    elsif params[:next_action] == 'stage'
      @file_status_resp = stage_file
    elsif params[:next_action] == 'unstage'
      @file_status_resp = unstage_file
    end
    puts params[:next_action]
    puts @file_status_resp

    respond_to do |wants|
      wants.html { presenter }
    end
  end

  def file_status

  end

  def stage

  end

  def unstage

  end

  private

  def get_file_status
    get_proxy_client
    @sp_client.filename = @filename
    response = @sp_client.status
    response.body
  end

  def stage_file
    get_proxy_client
    @sp_client.filename = @filename
    response = @sp_client.stage
    response.body
  end

  def unstage_file
    get_proxy_client
    @sp_client.filename = @filename
    response = @sp_client.unstage
    response.body
  end

  def get_proxy_client
    @sp_client = HydraDAM::StorageProxyClient.new
    begin
      @sp_client = HydraDAM::StorageProxyClient.new
    rescue
      puts "Getting a connection to the Storage Proxy failed"
    end
  end

end