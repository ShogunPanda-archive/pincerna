# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Pincerna
  # The current version of pincerna, according to semantic versioning.
  #
  # @see http://semver.org
  module Version
    # The major version.
    MAJOR = 1

    # The minor version.
    MINOR = 1

    # The patch version.
    PATCH = 2

    # The current version of pincerna.
    STRING = [MAJOR, MINOR, PATCH].compact.join(".")
  end
end
