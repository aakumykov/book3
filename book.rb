#!/usr/bin/env ruby
#coding: UTF-8

require 'sqlite3'
require 'net/http'

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
		Msg::debug("#{self.class}.#{__method__}()")

		until prepare_complete? do
			process_next_page
			puts ''
		end

		puts "Подготовка завершена"
	end

	def save
		Msg::debug("#{self.class}.#{__method__}()")
	end


	private
	
	class Processor
		def initialize(uri)
			Msg::debug("#{self.class}.#{__method__}(uri)")
			
			#@rules = get_rule(@uri.to_s)
		end
	
		def act
			Msg::debug("#{self.class}.#{__method__}()")

			rule = get_rule(@uri.to_s)
			
			#initial_page = get_page(lnk)
		
			#	Msg::debug "размер страницы: #{initial_page.lines.count} строк / #{initial_page.bytes.count} байт"

			#collect_links(initial_page, rules)

			# page = process_page(initial_page)
			# media = load_media(page,rules)
			
			return [nil, nil]
		end
		
		def get_rule(uri)
			Msg::debug("#{self.class}.#{__method__}()")
			
			return {}
			
			uri = URI(uri)
			
			case uri.host
			when 'opennet.ru'
				require 'rules/opennet_ru.rb'
				rules = OpennetRu.new
			when 'ru.wikipedia.org'
				require 'ru_wikipedia.org_rb'
				rules = RuWikipediaOrg.new
			else
				return rules = nil
			end
		end
		
		
	end
	
	def process_next_page
	
		lnk = get_next_link
				
			Msg::debug("следующая ссылка: #{lnk}")
		
		processor = Processor.new(lnk)
		
		page, media = processor.act

		# save_results(page, media)
		
		@page_count += 1
	end

	def prepare_complete?
		Msg::debug("#{self.class}.#{__method__}()")

		puts "page_limit: #{@page_limit}, page_count: #{@page_count}"
		puts "error_limit: #{@error_limit}, error_count: #{@error_count}"
		puts "depth_limit: #{@depth_limit}, depth: #{@depth}"

		return true if @page_count >= @page_limit
		return true if @error_count >= @error_limit
		return true if @depth > @depth_limit
	end

	def get_next_link
		Msg::debug("#{self.class}.#{__method__}()")
		
		res = @@db.execute("SELECT uri FROM #{@@table_name} WHERE processed=0 LIMIT 1")
		res.first.first
	end
	
	def load_page(uri)
		Msg::debug("#{self.class}.#{__method__}()")

		redirects_limit = 3
		
		raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0
		
		#uri = URI.escape(uri) if not uri.urlencoded?
		uri = URI(uri)

		data = {}

		Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

		  request = Net::HTTP::Get.new(uri.request_uri)
		  request['User-Agent'] = 'Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0'
		  
		  response = http.request request

		  case response
			when Net::HTTPRedirection then
				location = response['location']
				puts "перенаправление на '#{location}'"
				data =  self.work(
					:uri => location, 
					:redirects_limit => (redirects_limit-1)
				)
			when Net::HTTPSuccess then
				data = {
					:headers => response.to_hash,
					:page => response.body,
				}
			else
				response.value
		  end
		}
	  
	  return data
	end

	def recode_page(page, headers, target_charset='UTF-8')
		page_charset = nil
		headers_charset = nil
		
		pattern = Regexp.new(/charset\s*=\s*['"]?(?<charset>[^'"]+)['"]?/i)

		page_charset = page.match(pattern)
		page_charset = page_charset[:charset] if not page_charset.nil?
		
		headers.each_pair { |k,v|
			if 'content-type'==k.downcase.strip then
				res = v.first.downcase.strip.match(pattern)
				headers_charset = res[:charset].upcase if not res.nil?
			end
	    }
	    
	    page_charset = headers_charset if page_charset.nil?
	    page_charset = 'ISO-8859-1' if headers_charset.nil?

	    puts "page_charset: #{page_charset}"

	    page = page.encode(
			target_charset, 
			page_charset, 
			{ :replace => '_', :invalid => :replace, :undef => :replace }
		)

		page = page.gsub(pattern, "charset='UTF-8'")

		return page
	end

	def get_page(uri)
		data = load_page(uri)
		page = recode_page(data[:page], data[:headers])
		return page
	end


	def collect_links(page)
		Msg::debug("#{self.class}.#{__method__}()")
		#links = page.scan(/href\s*=\s*['"]([^'"]+)['"]/i)
	end
end


class Msg
	def self.debug(msg)
		puts msg
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
