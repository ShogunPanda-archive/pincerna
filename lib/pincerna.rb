# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "open-uri"
require "strscan"
require "cgi"
require "fileutils"
require "nokogiri"
require "oj"
require "yahoo_weatherman"
require "ruby-units"
require "plist"
require "daybreak"
require "em-synchrony"
require "em-synchrony/em-http"

require "pincerna/version" if !defined?(Pincerna::Version)
require "pincerna/base"
require "pincerna/cache"
require "pincerna/currency_conversion"
require "pincerna/ip"
require "pincerna/map"
require "pincerna/translation"
require "pincerna/unit_conversion"
require "pincerna/vpn"
require "pincerna/weather"
require "pincerna/bookmark"