require 'hydradam/presenters/storage_proxy_presenter'

module StorageControllerBehavior
  extend ActiveSupport::Concern
  require 'hydradam/storage_proxy_client'
  
  def show

    # require 'pry'; binding.pry

    storage_proxy_response = storage_proxy.status filename
    @storage_proxy_presenter = HydraDAM::StorageProxyPresenter.new(storage_proxy_response.body, file_set_solr_document)
    super
  end

  def stage
    stage_file filename
    redirect_to main_app.url_for(file_set_solr_document), notice: "Stage request for #{filename} has been sent"
  end

  def unstage
    unstage_file filename
    redirect_to main_app.url_for(file_set_solr_document), notice: "Unstage request for #{filename} has been sent"
  end

  def fixity
    check_fixity filename
    redirect_to main_app.url_for(file_set_solr_document), notice: "Fixity check request for #{filename} has been sent"
  end

  private

  def file_set_solr_document
    # TODO: how to handle invalid ID?
    @file_set_solr_document ||= curation_concern_type.load_instance_from_solr(params[:id])
  end

  def filename
    @filename ||= File.basename(file_set_solr_document.filename)
  end

  def get_file_status
    default_resp = {"name" => @filename, "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.status @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def stage_file(filename)
    default_resp = {"name" => filename, "type" => 'stage', "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.stage filename
      response.body
    else
      default_resp.to_json
    end
  end

  def unstage_file(filename)
    default_resp = {"name" => @filename, "type" => 'unstage', "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.unstage @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def check_fixity(filename, fixity_type = 'md5')
    default_resp = {"name" => @filename, "type" => 'fixity', "fixity_type" => fixity_type, "status" => 'disabled'}
    if storage_proxy.enabled?
      response = storage_proxy.fixity @filename
      response.body
    else
      default_resp.to_json
    end
  end

  def storage_proxy
    @storage_proxy ||= HydraDAM::StorageProxyClient.new
  end

end