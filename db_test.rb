#!/usr/bin/env ruby
# coding: utf-8

require "sqlite3"

table_name = 'links'

# Open a database
db = SQLite3::Database.new 'test.sqlite3'


db.execute("PRAGMA journal_mode = OFF")
#puts db.query('PRAGMA journal_mode').first;
db.execute("DROP TABLE IF EXISTS #{table_name}")
db.execute("CREATE TABLE #{table_name} (id INT PRIMARY KEY, uri VARCHAR(255), processed VARCHAR(1))")
10.times { |i|
	sql = "INSERT INTO #{table_name} (id, uri, processed) VALUES (#{i}, #{rand()}, 0)"
	db.query(sql) #and puts sql
}

threads = []

10.times {
	threads << Thread.new {
		100000.times do
			sql = "UPDATE #{table_name} SET processed='#{rand(2)}' WHERE id='#{rand(10)+1}'"
			db.query(sql) or puts "ОЩИБКА: #{sql}"
		end
	}
}

threads.each do |thr|
	thr.join
end
