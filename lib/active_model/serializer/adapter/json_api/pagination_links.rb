# https://github.com/rails-api/active_model_serializers/pull/1041#discussion_r37373943
# https://github.com/rails-api/active_model_serializers/pull/1041#discussion_r37346434
# https://github.com/rails-api/active_model_serializers/pull/1041#discussion_r37344511
require 'uri/http'
module ActiveModel
  class Serializer
    module Adapter
      class JsonApi < Base
        class PaginationLinks
          FIRST_PAGE = 1

          attr_reader :collection, :context
          class Paginatable
            attr_reader :pages, :total_pages, :current_page, :number_of_items
            def initialize(collection)
              @collection = collection
              @total_pages = collection.total_pages
              @current_page = collection.current_page
              @number_of_items = collection.size
              @pages = {}
            end

            def build_pages
              if total_pages != FIRST_PAGE
                pages[:self] = current_page

                if current_page != FIRST_PAGE
                  pages[:first] = FIRST_PAGE
                  pages[:prev]  = current_page - FIRST_PAGE
                end

                if current_page != total_pages
                  pages[:next] = current_page + FIRST_PAGE
                  pages[:last] = total_pages
                end
              end
            end
          end

          def initialize(collection, context)
            @collection = collection
            @context = context
          end

          def serializable_hash(options = nil)
            options ||= {}

            page_uri_params = page_uri_params(options)
            pages.each_with_object({}) do |(page_name, page_number), pagination_links|
              pagination_links[page_name] = page_link(page_uri_params.dup, page_number)
            end
          end

          private

          def page_link(page_uri_params, page_number)
            @number_of_items ||= collection.size

            page_link = {  page: { number: page_number, size: @number_of_items } }
            query_string = query_parameters.merge(page_link).to_query
            page_uri_params[:query] = query_string
            URI::HTTP.build(page_uri_params).to_s
          end

          def page_uri(options)
            @page_uri ||= URI(options.fetch(:links, {}).fetch(:self, nil) || request_url)
          end

          def page_uri_params(options)
            page_uri = page_uri(options)
            { scheme: page_uri.scheme, host: page_uri.host, path: page_uri.path }
          end

          def request_url
            @request_url ||= context.request_url
          end

          def query_parameters
            @query_parameters ||= context.query_parameters
          end
        end
      end
    end
  end
end
