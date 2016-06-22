#!/usr/bin/env ruby

# Regenerate tag and category pages

require 'fileutils'
require 'yaml'

def get_property propertyType
    properties = Array.new

    # Read post headers and collect tags
    Dir.glob( "_posts/*.md" ).each do | post |
        yaml = YAML.load( File.read( post ).split( /^---$/ ).at( 1 ) )

        properties += [ yaml[ propertyType ] ].flatten
    end

    # Retain unique, non-nil properties
    properties = properties.uniq
    properties = properties.delete_if { | property | property.nil? }

    return properties
end

def get_singular_form propertyType
    case propertyType
    when "categories"
        return "category"
    when "tags"
        return "tag"
    else
        return propertyType
    end
end

def write_property_pages propertyType
    # Overwrite existing directory
    FileUtils.remove_dir propertyType
    Dir.mkdir propertyType

    # Populate with pages
    propertyNames = get_property propertyType
    for propertyName in propertyNames
        singularForm = get_singular_form propertyType.downcase
        puts "Writing #{propertyType}/#{propertyName.downcase}.md"
        File.write "#{propertyType}/#{propertyName.downcase}.md", <<-EOF
---
layout: #{singularForm}page
#{singularForm}: #{propertyName}
---
EOF
    end
end

# Refresh category and tag pages
write_property_pages "categories"
write_property_pages "tags"

