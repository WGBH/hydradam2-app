module StorageControllerBehavior
  extend ActiveSupport::Concern
  require 'hydradam/storage_proxy_client'

  included do
    # This SHOULD authorize all of my actions below but it doesn't
    load_and_authorize_resource class: ::FileSet, except: :show
  end

  # TODO: Undo this ugly #show override with parameter tracking hack.
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

    respond_to do |wants|
      wants.html { presenter }
    end
  end

  # TODO: Why can I not route to file_status, stage, unstage actions?
  # This controller behavior is meant to provide direct routable actions
  # that redirect back to show, but they result in immediate redirect
  # back to application root with unauthorized error
  def file_status
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    @file_status_resp = get_file_status
    redirect_to @file_set
  end

  def stage
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    @file_status_resp = stage_file
    redirect_to @file_set
  end

  def unstage
    @file_set = curation_concern_type.load_instance_from_solr(params[:id]) unless curation_concern
    @filename = File.basename(@file_set.filename)
    @file_status_resp = unstage_file
    redirect_to @file_set
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