#!/usr/bin/env ruby

require 'zip'

name=__FILE__.gsub(/\.[^.]+$/,'')
zip_name="#{name}.zip"

Zip::OutputStream.open(zip_name) do |zos|
  zos.put_next_entry('the first little entry')
  zos.puts 'Hello hello hello hello hello hello hello hello hello'

  zos.put_next_entry('the second little entry')
  zos.puts 'Hello again'

  # Use rubyzip or your zip client of choice to verify
  # the contents of exampleout.zip
end
