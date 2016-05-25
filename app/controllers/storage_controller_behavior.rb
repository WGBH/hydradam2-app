module StorageControllerBehavior
  extend ActiveSupport::Concern
  require 'hydradam/storage_proxy_client'

  def file_status
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    session[:file_status_resp] = get_file_status
    session[:prev_file_action] = 'file_status'
    redirect_to [main_app, @file_set], notice: "Availability request for #{@filename} has been sent"
  end

  def stage
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    session[:file_status_resp] = stage_file
    session[:prev_file_action] = 'stage'
    redirect_to [main_app, @file_set], notice: "Stage request for #{@filename} has been sent"
  end

  def unstage
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    session[:file_status_resp] = unstage_file
    session[:prev_file_action] = 'unstage'
    redirect_to [main_app, @file_set], notice: "Unstage request for #{@filename} has been sent"
  end

  private

  def get_file_status
    get_proxy_client
    @sp_client.filename = @filename
    default_resp = {"name" => @filename, "status" => 'disabled'}
    if @sp_client.enabled?
      response = @sp_client.status
      response.body
    else
      default_resp.to_json
    end
  end

  def stage_file
    get_proxy_client
    @sp_client.filename = @filename
    default_resp = {"name" => @filename, "type" => 'stage', "status" => 'disabled'}
    if @sp_client.enabled?
      response = @sp_client.stage
      response.body
    else
      default_resp.to_json
    end
  end

  def unstage_file
    get_proxy_client
    @sp_client.filename = @filename
    default_resp = {"name" => @filename, "type" => 'unstage', "status" => 'disabled'}
    if @sp_client.enabled?
      response = @sp_client.unstage
      response.body
    else
      default_resp.to_json
    end
  end

  def get_proxy_client
    begin
      @sp_client = HydraDAM::StorageProxyClient.new
    rescue
      puts "Getting a connection to the Storage Proxy failed"
    end
  end

end