#!/usr/bin/env ruby
#coding: utf-8
system 'clear'


require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.sqlite"

db.results_as_hash = true

db.execute "drop table if exists 'students'"

# Create a database
rows = db.execute <<-SQL
  create table 'students' (
    name varchar(30),
    email varchar(30)
  );
SQL

# Execute a few inserts
{
  'Andrey' => 'aakumykov@yandex.ru',
  'Tanya' => 'kumykovat@yandex.ru',
}.each do |pair|
  db.execute "insert into students values ( ?, ? )", pair
end

res = db.query("SELECT * FROM students")
puts res

data = []
while row = res.next do
	puts "row: #{row}"
	data << row
end

puts "data: #{data}"
