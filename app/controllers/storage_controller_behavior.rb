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
    default_resp = {"name" => @filename, "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.status @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def stage_file
    default_resp = {"name" => @filename, "type" => 'stage', "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.stage @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def unstage_file
    default_resp = {"name" => @filename, "type" => 'unstage', "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.unstage @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def storage_proxy
    @storage_proxy ||= HydraDAM::StorageProxyClient.new
  end

end