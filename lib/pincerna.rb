# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "nokogiri"
require "oj"

$: << File.dirname(__FILE__)
require "pincerna/version" if !defined?(Pincerna::Version)
require "pincerna/base"