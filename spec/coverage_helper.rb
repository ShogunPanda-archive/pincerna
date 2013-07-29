# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "pathname"
require "simplecov"
require "coveralls"

Coveralls.wear! if ENV["CI"] || ENV["JENKINS_URL"] # Do not load outside Travis

SimpleCov.start do
  root = Pathname.new(File.dirname(__FILE__)) + ".."

  add_filter do |src_file|
    path = Pathname.new(src_file.filename).relative_path_from(root).to_s
    path !~ /^lib/
  end
end

# Backport this to fix an issue with ruby-units (https://github.com/colszowka/simplecov/pull/175).
# Remove once Simplecov reaches v-0.8.0.
class SimpleCov::FileList < Array
  def covered_strength
    return 0 if empty? or lines_of_code == 0
    map {|f| f.covered_strength }.inject(&:+).to_f / size
  end
end

class SimpleCov::SourceFile
  def covered_percent
    return 100.0 if lines.length == 0 or lines.length == never_lines.count
    relevant_lines = lines.count - never_lines.count - skipped_lines.count
    if relevant_lines == 0
      0
    else
      (covered_lines.count) * 100.0 / relevant_lines.to_f
    end
  end
end


