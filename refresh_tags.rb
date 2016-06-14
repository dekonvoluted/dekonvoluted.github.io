#!/usr/bin/env ruby

# Generate tag pages

require 'fileutils'
require 'yaml'

# Determine all tags
tags = Array.new

Dir.glob( "_posts/*.md" ).each do | post |
    # Read header of each post and find tags
    yaml = YAML.load( File.read( post ).split( /^---$/ ).at( 1 ) )
    begin
        # Add array of tags
        tags += yaml[ "tags" ]
    rescue
        # Or a single tag
        tags += [ yaml[ "tags" ] ]
    end
end

# Clear old tag pages
Dir.glob( "tags/*" ).each do | tagpage |
    FileUtils.rm tagpage
end

# Create tag pages
tags.uniq.each do | tag |
    File.write "tags/#{tag.downcase}.md", <<-EOF
---
layout: tagpage
tag: #{tag}
---
EOF
end



