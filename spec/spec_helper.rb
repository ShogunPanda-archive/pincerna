# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "rubygems"
require "vcr"
require "bundler/setup"
require "pincerna"

VCR.configure do |config|
  config.cassette_library_dir = File.dirname(__FILE__) + "/cassettes"
  config.hook_into(:webmock)
  config.default_cassette_options = {record: :once}
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = false
end

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.around do |example|
    if example.metadata[:synchronous] then
      EM.synchrony do
        example.run
        EM.stop
      end
    else
      example.run
    end
  end
end

RSpec::Matchers.define(:eq_as_yaml) { |expected|
  match do |actual| YAML.load(actual) == expected end
}

RSpec::Matchers.define(:eq_as_unit) { |expected|
  match do |actual|
    actual.scalar.to_f == expected.scalar.to_f && actual.unit_name == expected.unit_name
  end
}