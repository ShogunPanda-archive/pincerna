# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require File.expand_path('../lib/pincerna/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "pincerna"
  gem.version = Pincerna::Version::STRING
  gem.homepage = "http://sw.cowtech.it/pincerna"
  gem.summary = "A bunch of useful Alfred 2 workflows."
  gem.description = "A bunch of useful Alfred 2 workflows."
  gem.rubyforge_project = "pincerna"

  gem.authors = ["Shogun"]
  gem.email = ["shogun@cowtech.it"]
  gem.license = "MIT"

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.3.0"

  gem.add_dependency("goliath", "~> 1.0")
  gem.add_dependency("em-http-request", "~> 1.1")
  gem.add_dependency("nokogiri", "~> 1.6")
  gem.add_dependency("ruby-units", "~> 2.0")
  gem.add_dependency("yahoo_weatherman", "~> 2.0")
  gem.add_dependency("oj", "~> 2.15")
  gem.add_dependency("plist", "~> 3.2")
  gem.add_dependency("daybreak", "~> 0.3")
end
