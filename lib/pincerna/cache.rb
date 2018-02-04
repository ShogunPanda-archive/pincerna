# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Pincerna
  # A utility class to handle caching.
  #
  # @attribute [r] data
  #   @return [Daybreak::DB] The cache store.
  class Cache
    # Expiration of keys.
    EXPIRATIONS = {short: 1800, long: 2592000} # 30 min, 1 month

    # Location of the cache file
    FILE = Pincerna::Base::CACHE_ROOT + "/cache.db"

    attr_reader :data

    # Returns the instance of the cache.
    def self.instance
      @instance ||= Pincerna::Cache.new
    end

    # Creates a new cache object.
    def initialize
      FileUtils.mkdir_p(File.dirname(FILE))
      @data = Daybreak::DB.new(FILE)
      @flusher = EM.add_periodic_timer(5) { Pincerna::Cache.instance.flush }
    end

    # Closes the cache data.
    def destroy
      @flusher.cancel
      @data.close rescue nil
    end

    # Flush data into disk.
    def flush
      @data.flush
      @data.compact
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
