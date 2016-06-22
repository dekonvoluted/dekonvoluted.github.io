#!/usr/bin/env ruby

# Generate category pages

require 'fileutils'
require 'yaml'

# Determine all categories
categories = Array.new

Dir.glob( "_posts/*.md" ).each do | post |
    # Read header of each post and find categories
    yaml = YAML.load( File.read( post ).split( /^---$/ ).at( 1 ) )
    begin
        # Add array of categories
        categories += yaml[ "categories" ]
    rescue
        # Or a single category
        categories += [ yaml[ "categories" ] ]
    end
end

categories = categories.uniq
categories = categories.delete_if { | category | category.nil? }

# Clear old category pages
Dir.glob( "categories/*" ).each do | categorypage |
    FileUtils.rm categorypage
end

# Create category pages
categories.each do | category |
    File.write "categories/#{category.downcase}.md", <<-EOF
---
layout: categorypage
category: #{category}
---
EOF
end

