#!/usr/bin/env ruby
# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Main HTTP server to handle requests.
  class Server < Goliath::API
    use Goliath::Rack::Params
    use Goliath::Rack::Heartbeat
    use Goliath::Rack::Validation::RequestMethod, %w(GET)

    # Delay before responding to a request.
    DELAY=0.05

    # Enqueues a request.
    def self.enqueue_request
      @requests ||= Queue.new
      @requests << Time.now.to_f
      EM::Synchrony.sleep(DELAY)
    end

    # Enqueues a request.
    #
    # @return [Boolean] `true` if the request was the last arrived and therefore must be performed, `false` otherwise.
    def self.perform_request?
      @requests.pop
      @requests.empty?
    end

    # Handles a valid request.
    #
    # @param type [String] The type of request.
    # @param args [Hash] The parameters of the request.
    # @return [Array] A response complaint to Rack interface.
    def handle_request(type, args)
      # Enqueue the request. This will wait to avoid too many requests.
      Server.enqueue_request

      # Execute the request, if none were added.
      response = Server.perform_request? ? Pincerna::Base.execute!(type, (args["q"] || "").strip, args["format"], args["debug"]) : false

      if response then
        [200, {"Content-Type" => response.format_content_type}, response.output]
      else
        [response.nil? ? 404 : 429, {"Content-Type" => "text/plain"}, ""]
      end
    end

    # Schedule the server's stop.
    # @return [Array] A response complaint to Rack interface.
    def stop_server
      EM.add_timer(0.1) { perform_stop_server }
      [200, {}, ""]
    end

    # Send a response to a request.
    #
    # @param env [Goliath::Env] The environment of the request.
    # @return [Array] A response complaint to Rack interface.
    def response(env)
      begin
        type = env["REQUEST_PATH"].gsub(/\//, "")
        type != "quit" ? handle_request(type, params) : stop_server
      rescue => e
        [500, {"X-Error" => e.class.to_s, "X-Error-Message" => e.message, "Content-Type" => "text/plain"}, e.backtrace.join("\n")]
      end
    end

    private
      # Stops the server.
      def perform_stop_server
        Pincerna::Cache.instance.destroy
        EM.stop
      end
  end
end