module HydraDAM
  class StorageProxyPresenter
    attr_accessor :storage_proxy_response

    def initialize(storage_proxy_response, file_set_solr_document)
      @file_set_solr_document = file_set_solr_document
      @storage_proxy_response = JSON.parse(storage_proxy_response, quirks_mode: true)
    end

    def status
      case(@storage_proxy_response["status"])
      when "staging"
        :staging
      when "staged"
        :staged
      when "calculating checksum"
        :calculating_checksum
      when nil
        :not_cached
      end
    end

    def actions
      case status
      when :staged
        [
          { title: "Download", link: @storage_proxy_response["url"] },
          { title: "Fixity", link: url_helpers.fixity_curation_concerns_file_set_path(@file_set_solr_document) },
          { title: "Unstage", link: url_helpers.unstage_curation_concerns_file_set_path(@file_set_solr_document) }
        ]
      when :not_cached
        [
          { title: "Stage", link: url_helpers.stage_curation_concerns_file_set_path(@file_set_solr_document) },
          { title: "Fixity", link: url_helpers.fixity_curation_concerns_file_set_path(@file_set_solr_document) }
        ]
      else
        # always return an array so the view won't choke when calling #each
        []
      end
    end


    def status_phrase
      status_phrases = {
        not_cached: "Not Cached",
        staging: "Staging",
        staged: "Staged",
        calculating_checksum: "Calculating Checksum"
      }
      status_phrases[status]
    end

    private 

    def url_helpers
      @url_helpers ||= Rails.application.routes.url_helpers
    end
  end
end
