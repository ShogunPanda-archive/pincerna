# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # A utility class to handle caching.

  class Cache
    # Returns the instance of the cache.
    def self.instance
      @instance ||= Pincerna::Cache.new
    end

    # Creates a new cache object.
    def initialize
      FileUtils.mkdir_p("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/it.cowtech.pincerna")
      @data = Daybreak::DB.new(File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/it.cowtech.pincerna/cache.db"))

      @flusher = EM.add_period_timer(1) do
        @data.flush
        @data.compact
      end
    end

    # Closes the cache data.
    def destroy
      @flusher.cancel
      @data.close
    end

    # Use data from cache or fetches new data.
    #
    # @param key [String] The key of the data.
    # @param expiration [Fixnum] Expiration of new data, in seconds.
    def use(key, expiration)
      value = @data[key]

      if !value || Time.now.to_f > value[:expiration] then
        data = yield
        @data[key] = {data: data, expiration: Time.now.to_f + expiration}
        data
      else
        value[:data]
      end
    end
  end
end
