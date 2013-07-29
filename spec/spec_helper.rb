# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "rubygems"
require "bundler/setup"
require "vcr"

require "pincerna"
require "pincerna/currency_conversion"
require "pincerna/ip"
require "pincerna/map"
require "pincerna/translation"
require "pincerna/unit_conversion"
require "pincerna/vpn"
require "pincerna/weather"

ENV["PINCERNA_DEBUG"] = "true"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.treat_symbols_as_metadata_keys_with_true_values = true
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into(:webmock)
  config.default_cassette_options = {record: :new_episodes}
  config.configure_rspec_metadata!
end

RSpec::Matchers.define(:eq_as_yaml) { |expected|
  match do |actual| YAML.load(actual) == expected end
}


