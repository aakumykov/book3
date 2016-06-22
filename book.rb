#!/usr/bin/env ruby
#coding: UTF-8

require 'sqlite3'

class Book
	attr_reader :title, :author, :language
	attr_accessor :page_limit, :error_limit, :depth_limit

	def initialize
		@title = 'Новая книга'
		@author = 'Неизвестный автор'
		@language = 'ru'

		@source = []

		@page_limit = 0
		@error_limit = 5
		@depth_limit = 0

		@page_count = 0
		@error_count = 0
		@depth = 0
		
		# настройка БД
		@@db_name = 'links.sqlite3'
		@@table_name = 'table1'

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


	def title=(a_title)
		raise 'некорректное название книги' if a_title.strip.empty?
		@title = a_title
	end

	def author=(an_author)
		raise 'некорректное имя автора' if an_author.strip.empty?
		@author = an_author
	end

	def language=(a_language)
		a_language.strip!
		raise 'некорректный язык книги' if not a_language.match(/^[a-z]{2}$/)
		@language = a_language
	end


	def add_source(src)
		@@db.execute(
			"INSERT INTO #{@@table_name} (parent_id, uri) VALUES (?, ?)",
			0,
			src
		)
	end


	def prepare
		puts "#{self.class}.#{__method__}()"

		until prepare_complete? do
			process_next_page
			puts ''
		end

		puts "Подготовка завершена"
	end

	def prepare_complete?
		puts "#{self.class}.#{__method__}()"

		puts "page_limit: #{@page_limit}, page_count: #{@page_count}"
		puts "error_limit: #{@error_limit}, error_count: #{@error_count}"
		puts "depth_limit: #{@depth_limit}, depth: #{@depth}"

		return true if @page_count >= @page_limit
		return true if @error_count >= @error_limit
		return true if @depth > @depth_limit
	end

	def process_next_page
		puts "#{self.class}.#{__method__}()"
		
		@page_count += 1

		lnk = get_next_link
		# rules = find_rules(lnk)

		# raw_page = load_page(lnk)

		# collect_links(raw_page, rules)

		# page = process_page(raw_page)
		# media = load_media(page,rules)
		
		# save_results(page, media)
	end

	def get_next_link
		puts "#{self.class}.#{__method__}()"
		
		res = @@db.execute("SELECT uri FROM #{@@table_name} WHERE processed=0 LIMIT 1")
		uri = res.first.first
		
		Msg::debug("свежая ссылка: #{uri}")
		
		uri
	end

	def save
		puts "#{self.class}.#{__method__}()"
	end
end


class Msg
	def self.debug(msg)
		puts "ОТЛАДКА: #{msg}"
	end
	
	def self.info(msg)
		puts msg
	end
	
	def self.error(msg)
		STDERR.puts "ОШИБКА: #{msg}"
	end
end


book = Book.new

book.title = 'Пробная книга'
book.author = 'Кумыков Андрей'
book.language = 'ru'

book.add_source 'http://opennet.ru'
book.add_source 'http://geektimes.ru'

book.page_limit = 3

book.prepare
book.save

puts ''
puts book.inspect
