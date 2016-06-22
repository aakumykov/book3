#!/usr/bin/env ruby
#coding: UTF-8

require 'sqlite3'

class LinksDB
	@@db_name = 'links.sqlite3'
	@@db = nil
	
	def self.prepare(table_name)
		@@table_name = table_name
		
		@@db = SQLite3::Database.new @@db_name

		@@db.execute("PRAGMA journal_mode = OFF")

		@@db.execute("DROP TABLE IF EXISTS #{@@table_name}")

		@@db.execute("
			CREATE TABLE #{@@table_name} (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				parent_id INTEGER,
				uri TEXT,
				processed BOOLEAN DEFAULT 0
			)"
		)
	end

	def self.add(parent_id, uri)
		@@db.execute(
			"INSERT INTO #{@@table_name} (parent_id, uri) VALUES (?,?)",
			parent_id,
			uri
		)
	end

	def self.get(params)
		case params.class.to_s
		when 'Hash'
			key = params.keys.first.to_s
			value = params.values.first.to_s

			puts "#{key}: #{value}"
		else
			raise "некорректный аргумент (#{params.class}), требуется Hash"
		end

		return @@db.execute("SELECT * FROM #{@@table_name} WHERE ?='?'", key, value).first
	end
end

LinksDB::prepare('book1')
LinksDB.add(0,'http://opennet.ru')
LinksDB.get(parent_id:0)