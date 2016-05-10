class CatalogController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller
  include CurationConcerns::CatalogController
  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'dismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    # config.search_builder_class = ::SearchBuilder
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qf: [  solr_name('title', :stored_searchable),
             solr_name('description', :stored_searchable),
             solr_name('filename', :stored_searchable),
             solr_name('file_format', :stored_searchable),
             solr_name('quality_level', :stored_searchable),
             solr_name('lto_path', :stored_searchable),
             solr_name('artesia_uoi_id', :stored_searchable),
             solr_name('creator', :stored_searchable),
             solr_name('original_checksum', :symbol),
             'file_size_ltsi', 'file_size_mb_ltsi'
      ],
      qt: 'search',
      rows: 10
    }

    # solr field configuration for search results/index views
    config.index.title_field = solr_name('title', :stored_searchable)
    config.index.display_type_field = solr_name('has_model', :symbol)

    config.index.thumbnail_field = 'thumbnail_path_ss'
    config.index.partials.delete(:thumbnail) # we render this inside _index_default.html.erb
    config.index.partials += [:action_menu]

    # solr field configuration for document/show views
    # config.show.title_field = solr_name("title", :stored_searchable)
    # config.show.display_type_field = solr_name("has_model", :symbol)

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name('human_readable_type', :facetable)
    config.add_facet_field solr_name('creator', :facetable), limit: 5
    config.add_facet_field solr_name('tag', :facetable), limit: 5
    config.add_facet_field solr_name('subject', :facetable), limit: 5
    config.add_facet_field solr_name('language', :facetable), limit: 5
    config.add_facet_field solr_name('based_near', :facetable), limit: 5
    config.add_facet_field solr_name('publisher', :facetable), limit: 5
    config.add_facet_field solr_name('file_format', :symbol), label: 'File Format', limit: 5
    config.add_facet_field solr_name('depositor', :symbol),label: 'Depositor', limit: 5
    config.add_facet_field solr_name('quality_level', :stored_searchable), label: 'Quality Level', limit: 5
    config.add_facet_field 'file_size_mb_ltsi', label: 'File Size (MB)', limit: 5, range: true


    config.add_facet_field 'generic_type_sim', show: false, single: true

    config.add_facet_field 'date_range', label: 'Date range', limit: 5, range: true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name('description', :stored_searchable)
    config.add_index_field solr_name('tag', :stored_searchable)
    config.add_index_field solr_name('subject', :stored_searchable)
    config.add_index_field solr_name('creator', :stored_searchable)
    config.add_index_field solr_name('contributor', :stored_searchable)
    config.add_index_field solr_name('publisher', :stored_searchable)
    config.add_index_field solr_name('based_near', :stored_searchable)
    config.add_index_field solr_name('language', :stored_searchable)
    config.add_index_field solr_name('date_uploaded', :stored_sortable)
    config.add_index_field solr_name('date_modified', :stored_sortable)
    config.add_index_field solr_name('date_created', :stored_searchable)
    config.add_index_field solr_name('rights', :stored_searchable)
    config.add_index_field solr_name('human_readable_type', :stored_searchable)
    config.add_index_field solr_name('format', :stored_searchable)
    config.add_index_field solr_name('identifier', :stored_searchable)

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.
    #
    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.
    config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: true) do |field|
      title_name = solr_name('title', :stored_searchable, type: :string)
      label_name = solr_name('title', :stored_searchable, type: :string)
      contributor_name = solr_name('contributor', :stored_searchable, type: :string)
      field.solr_parameters = {
        #qf: "#{title_name} #{label_name} file_format_tesim #{contributor_name} file_size_ltsi",
        pf: title_name.to_s
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.
    # creator, title, description, publisher, date_created,
    # subject, language, resource_type, format, identifier, based_near,
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name('title', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('filesize') do |field|
      solr_name = solr_name('filesize', :stored_searchable, type: :long)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format_name') do |field|
      solr_name = solr_name('hasFormatName', :stored_searchable, type: :string)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date') do |field|
      solr_name = uploaded_field
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end

    config.add_search_field('checksum') do |field|
      solr_name = solr_name('checksum', :stored_searchable, type: :string)
      field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
      }
    end


    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance \u25BC"
    config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
    config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
    config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
    config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"
    config.add_sort_field "#{solr_name('duration', :stored_searchable, type: :string)} desc", label: "duration \u25BC"
    config.add_sort_field "#{solr_name('duration', :stored_searchable, type: :string)} asc", label: "duration \u25B2"
    config.add_sort_field "#{solr_name('bitRate', :stored_searchable, type: :string)} desc", label: "bit rate \u25BC"
    config.add_sort_field "#{solr_name('bitRate', :stored_searchable, type: :string)} asc", label: "bit rate \u25B2"
    config.add_sort_field "#{solr_name('sampleRate', :stored_searchable, type: :string)} desc", label: "sample rate \u25BC"
    config.add_sort_field "#{solr_name('sampleRate', :stored_searchable, type: :string)} asc", label: "sample rate \u25B2"
    config.add_sort_field "#{solr_name('width', :stored_searchable, type: :string)} desc", label: "video width \u25BC"
    config.add_sort_field "#{solr_name('width', :stored_searchable, type: :string)} asc", label: "video width \u25B2"
    config.add_sort_field "#{solr_name('height', :stored_searchable, type: :string)} desc", label: "video height \u25BC"
    config.add_sort_field "#{solr_name('height', :stored_searchable, type: :string)} asc", label: "video height \u25B2"


    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end
end
