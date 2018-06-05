require 'pact_broker/client/retry'

module PactBroker
  module Client
    module Hal
      class HttpClient
        attr_accessor :username, :password

        def initialize options = {}
          @username = options[:username]
          @password = options[:password]
        end

        def get href, params = {}, headers = {}
          query = params.collect{ |(key, value)| "#{CGI::escape(key)}=#{CGI::escape(value)}" }.join("&")
          uri = URI(href)
          uri.query = query if query && query.size > 0
          perform_request(create_request(uri, 'Get', nil, headers), uri)
        end

        def put href, body = nil, headers = {}
          uri = URI(href)
          perform_request(create_request(uri, 'Put', body, headers), uri)
        end

        def post href, body = nil, headers = {}
          uri = URI(href)
          perform_request(create_request(uri, 'Post', body, headers), uri)
        end

        def create_request uri, http_method, body = nil, headers = {}
          request = Net::HTTP.const_get(http_method).new(uri.to_s)
          request['Content-Type'] = "application/json" if ['Post', 'Put', 'Patch'].include?(http_method)
          request['Accept'] = "application/hal+json"
          headers.each do | key, value |
            request[key] = value
          end

          request.body = body if body
          request.basic_auth username, password if username
          request
        end

        def perform_request request, uri
          options = {:use_ssl => uri.scheme == 'https'}
          response = Retry.until_true do
            Net::HTTP.start(uri.host, uri.port, :ENV, options) do |http|
              http.request request
            end
          end
          Response.new(response)
        end

        class Response < SimpleDelegator
          def body
            __getobj__().body
          end

          def body_hash
            bod = __getobj__().body
            if bod && bod != ''
              JSON.parse(bod)
            else
              nil
            end
          end

          def success?
            __getobj__().code.start_with?("2")
          end

          def code
            __getobj__().code.to_i
          end
        end
      end
    end
  end
end
