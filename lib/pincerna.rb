# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

current_dir = File.dirname(__FILE__)
if !defined?(require_relative) then
  alias :require_relative :require
end

require "rubygems"
require "builder"
require "json"
require "restclient"
require "rexml/document"
require "vcr"
require "vcr/util/version_checker"
require "webmock"
require "ruby-units"
require "fileutils"
require "open-uri"

require current_dir + "/pincerna/version" if !defined?(Pincerna::Version)
require current_dir + "/pincerna/base"
require current_dir + "/pincerna/unit_conversion"
require current_dir + "/pincerna/currency_conversion"
require current_dir + "/pincerna/translation"
require current_dir + "/pincerna/map"
require current_dir + "/pincerna/weather"
require current_dir + "/pincerna/ip"
require current_dir + "/pincerna/vpn"

VCR.configure do |c|
  # Hide VCR warning about webmock
  VCR::VersionChecker.class_eval do
    private
    def warn_about_too_high
    end
  end

  c.allow_http_connections_when_no_cassette = true
  # TODO@SP: Change this to be in the correct cache dir: http://www.alfredforum.com/topic/307-workflows-best-practices/
  c.cassette_library_dir = Pincerna::Base::ROOT + "/cache"
  c.default_cassette_options = {:record => :new_episodes}
  c.hook_into :webmock
end