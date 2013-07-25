# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require File.expand_path('../lib/pincerna/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = "pincerna"
  gem.version = Pincerna::Version::STRING
  gem.homepage = "http://sw.cow.tc/pincerna"
  gem.summary = "A bunch of useful Alfred 2 workflows."
  gem.description = "A bunch of useful Alfred 2 workflows."
  gem.rubyforge_project = "pincerna"

  gem.authors = ["Shogun"]
  gem.email = ["shogun_panda@me.com"]

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("builder", "~> 3.2.2")
  gem.add_dependency("json_pure", "~> 1.8.0")
  gem.add_dependency("rest-client", "~> 1.6.7")
  gem.add_dependency("ruby-units", "~> 1.4.4")
  gem.add_dependency("webmock", "~> 1.13.0")
  gem.add_dependency("vcr", "~> 2.5.0")
end
