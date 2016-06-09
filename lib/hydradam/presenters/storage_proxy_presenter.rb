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
      when "unstaging"
          :staged
      when "calculating checksum"
        :calculating_checksum
      when "disabled"
        :disabled
      when nil
        :not_cached
      end
    end

    def actions
      case status
      when :staged
        [
          # Download link
          { title: I18n.t("curation_concerns.storage_proxy.actions.download.title"),
            link: @storage_proxy_response["url"] },
          # Fixity link
          { title: I18n.t("curation_concerns.storage_proxy.actions.fixity.title"),
            link: url_helpers.fixity_curation_concerns_file_set_path(@file_set_solr_document) },
          # Unstage link
          { title: I18n.t("curation_concerns.storage_proxy.actions.unstage.title"),
            link: url_helpers.unstage_curation_concerns_file_set_path(@file_set_solr_document) }
        ]
      when :not_cached
        [
          # Stage link
          { title: I18n.t("curation_concerns.storage_proxy.actions.stage.title"),
            link: url_helpers.stage_curation_concerns_file_set_path(@file_set_solr_document) },
          # Fixity link
          { title: I18n.t("curation_concerns.storage_proxy.actions.fixity.title"),
            link: url_helpers.fixity_curation_concerns_file_set_path(@file_set_solr_document) }
        ]
      when :calculating_checksum
        [
          # Download link
          { title: I18n.t("curation_concerns.storage_proxy.actions.download.title"),
            link: @storage_proxy_response["url"] },
          # Unstage link
          { title: I18n.t("curation_concerns.storage_proxy.actions.unstage.title"),
            link: url_helpers.stage_curation_concerns_file_set_path(@file_set_solr_document) },
        ]
      when :disabled
        []
      else
        # always return an array so the view won't choke when calling #each
        []
      end
    end

    def fixity_type
      @storage_proxy_response["fixity_type"]
    end

    def fixity_date
      DateTime.parse(@storage_proxy_response["fixity_date"]).strftime("%Y-%m-%d %H:%M:%S")
    end

    def fixity_available
      !!@storage_proxy_response["fixity_available"]
    end

    def checksum
      @storage_proxy_response["checksum"]
    end

    def status_phrase
      status_phrases = {
        not_cached: I18n.t("curation_concerns.storage_proxy.status_phrase.not_cached"),
        staging: I18n.t("curation_concerns.storage_proxy.status_phrase.staging"),
        staged: I18n.t("curation_concerns.storage_proxy.status_phrase.staged"),
        unstaging: I18n.t("curation_concerns.storage_proxy.status_phrase.unstaging"),
        calculating_checksum: I18n.t("curation_concerns.storage_proxy.status_phrase.calculating_checksum"),
        disabled: I18n.t("curation_concerns.storage_proxy.status_phrase.disabled")
      }
      status_phrases[status]
    end

    private 

    def url_helpers
      @url_helpers ||= Rails.application.routes.url_helpers
    end
  end
end
