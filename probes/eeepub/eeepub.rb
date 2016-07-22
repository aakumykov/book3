#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'eeepub'

epub = EeePub.make do
  title       'sample'
  creator     'jugyo'
  publisher   'jugyo.org'
  date        '2010-05-06'
  identifier  'http://example.com/book/foo', :scheme => 'URL'
  uid         'http://example.com/book/foo'

  files ['./1.html', './2.html'] # or files [{'/path/to/foo.html' => 'dest/dir'}, {'/path/to/bar.html' => 'dest/dir'}]
#  files [
#	  {'./tmp/text/1.html' => 'text/'}, 
#	  {'./tmp/text/2.html' => 'text/'}, 
#  ]

#  nav [
#    {:label => '1. foo', :content => 'foo.html', :nav => [
#      {:label => '1.1 foo-1', :content => 'foo.html#foo-1'}
#    ]},
#    {:label => '1. bar', :content => 'bar.html'}
#  ]
end

epub.save('sample.epub')
