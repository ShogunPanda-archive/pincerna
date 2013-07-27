# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# \curl -L https://get.rvm.io | sudo bash -s stable
# rvm install 1.9.3
# rvm use 1.9.3 --default
# gem i bundler pincerna
# gem i pincerna

current_dir = File.dirname(__FILE__)
if !defined?(require_relative) then
  alias :require_relative :require
end

require "rubygems"
require "nokogiri"

require current_dir + "/pincerna/version" if !defined?(Pincerna::Version)
require current_dir + "/pincerna/base"