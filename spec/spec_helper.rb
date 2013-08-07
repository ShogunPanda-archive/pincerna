# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "rubygems"
require "webmock"
require "vcr"
require "bundler/setup"

require "pincerna"
require "pincerna/currency_conversion"
require "pincerna/ip"
require "pincerna/map"
require "pincerna/translation"
require "pincerna/unit_conversion"
require "pincerna/vpn"
require "pincerna/weather"

ENV["PINCERNA_DEBUG"] = "spec"

def configure_vcr
  VCR.configure do |config|
    config.cassette_library_dir = File.dirname(__FILE__) + "/cassettes"
    config.hook_into(:webmock)
    config.default_cassette_options = {record: :once}
    config.configure_rspec_metadata!
    config.allow_http_connections_when_no_cassette = false
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.treat_symbols_as_metadata_keys_with_true_values = true
end

RSpec::Matchers.define(:eq_as_yaml) { |expected|
  match do |actual| YAML.load(actual) == expected end
}

RSpec::Matchers.define(:eq_as_unit) { |expected|
  match do |actual|
    actual.scalar.to_f == expected.scalar.to_f && actual.unit_name == expected.unit_name
  end
}

configure_vcr

