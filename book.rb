#!/usr/bin/env ruby
#coding: UTF-8

require 'sqlite3'
require 'net/http'

class Book
	attr_reader :title, :author, :language
	attr_accessor :page_limit, :error_limit, :depth_limit

	@@db_name = 'links.sqlite3'
	@@table_name = 'table1'
	
	@@rules_dir = './rules'
	@@work_dir = 'book_tmp'

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
		@@db = SQLite3::Database.new @@db_name
		@@db.execute("PRAGMA journal_mode = OFF")

		@@db.execute("DROP TABLE IF EXISTS #{@@table_name}")
		@@db.execute("
			CREATE TABLE #{@@table_name} (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				parent_id INTEGER,
				uri TEXT,
				processed BOOLEAN DEFAULT 0,
				file TEXT
			)"
		)
		
		if not Dir.exists?(@@work_dir) then
			Dir.mkdir(@@work_dir) or raise "невозможно создать каталог #{@@work_dir}"
		end
		
		@@images_dir = File.join(@@work_dir,'images')
		
		if not Dir.exists?(@@images_dir) then
			Dir.mkdir(@@images_dir) or raise "невозможно создать каталог #{@@images_dir}"
		end
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
		src.strip!
	
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
	
	def process_next_page
		Msg::debug("#{self.class}.#{__method__}()")
		
		@page_count += 1

		lnk = get_link
		
		rule = get_rule(lnk)

		page = get_page(lnk)

		collect_links(uri: lnk, page: page, rule: rule)

		page = process_page(uri: lnk, page: page, rule: rule)
		
		media = load_images(uri: lnk, page: page, rule: rule)
		
		media.each_pair { |orig_link,full_link|
			page = page.gsub(orig_link,full_link) if full_link
		}
		
		File.write('page.html', page)
		
		save_results(page, media)
	end

	def prepare_complete?
		Msg::debug("#{self.class}.#{__method__}()", nobr: true)

		Msg::debug(", pages: #{@page_count}/#{@page_limit}, errors: #{@error_count}/#{@error_limit}, depth: #{@depth}/#{@depth_limit}")

		return true if @page_count >= @page_limit
		return true if @error_count >= @error_limit
		return true if @depth > @depth_limit
	end

	def get_link
		Msg::debug("#{self.class}.#{__method__}()", nobr: true)
		
		res = @@db.execute("SELECT uri FROM #{@@table_name} WHERE processed=0 LIMIT 1")
		lnk = res.first.first
		
		Msg::debug("-> #{lnk}")
		
		return lnk
	end
	
	def get_rule(uri)
		Msg::debug("#{self.class}.#{__method__}(#{uri})")
		
		host = URI(uri).host
		file_name = host.gsub('.','_') + '.rb'
		class_name = host.split('.').map{|c| c.capitalize }.join
		
			#Msg::debug(" host: #{host}, file_name: #{file_name}, class_name: #{class_name}")
		
		case host
		when 'opennet.ru'
			require "#{@@rules_dir}/#{file_name}"
			rule = Object.const_get(class_name).new
		else
			return rule = nil
		end
	end

	def get_page(uri)
		Msg::debug("#{self.class}.#{__method__}()", nobr: true)
		
		data = load_page(uri: uri)
		page = recode_page(data[:page], data[:headers])
		
		Msg::debug "-> #{page.lines.count} строк, #{page.bytes.count} байт"
		
		return page
	end

	def get_image(uri)
		Msg::debug("#{__method__}(#{uri})")

		data = load_page(uri: uri)

		#~ return {
			#~ data: data[:page],
			#~ extension: 'jpg',
		#~ }
	end
	
	def load_page(arg)
		#Msg::debug("#{self.class}.#{__method__}(#{uri})")

		#uri = URI.escape(uri) if not uri.urlencoded?
		
		uri = URI(arg[:uri])
		redirects_limit = arg[:redirects_limit] || 10		# опасная логика...
		
		raise ArgumentError, 'слишком много перенаправлений' if redirects_limit == 0

		data = {}

		Net::HTTP.start(uri.host, uri.port, :use_ssl => 'https'==uri.scheme) { |http|

			request = Net::HTTP::Get.new(uri.request_uri)
			request['User-Agent'] = 'Mozilla/5.0 (X11; Linux i686; rv:39.0) Gecko/20100101 Firefox/39.0'

			response = http.request request

			case response
			when Net::HTTPRedirection then
				location = response['location']
				puts "перенаправление на '#{location}'"
				data =  send(
					__method__,
					{ :uri => location, :redirects_limit => (redirects_limit-1) }
				)
			when Net::HTTPSuccess then
				data = {
					:page => response.body,
					:headers => response.to_hash,
				}
			else
				response.value
			end
		}
		
		#puts "========== Headers: =========="
		#data[:headers].each_pair { |k,v| puts "#{k}: #{v}" }
		#puts "=========================="
	  
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

	    #puts "page_charset: #{page_charset}"

	    page = page.encode(
			target_charset, 
			page_charset, 
			{ :replace => '_', :invalid => :replace, :undef => :replace }
		)

		page = page.gsub(pattern, "charset=UTF-8")

		return page
	end

	def collect_links(params)
		Msg::debug("#{self.class}.#{__method__}()", nobr: true)
		
		page = params[:page]
		rule = params[:rule]
		
		links = repair_uri(
			params[:uri],
			page.scan(/href\s*=\s*['"]([^'"]+)['"]/).map { |lnk| lnk.first }
		)
		
			Msg::debug(", собрано ссылок: #{links.count}", nobr: true)
		
		links.keep_if { |lnk| rule.accept_link?(lnk) }
		
			Msg::debug(", оставлено: #{links.count}")
		
		return links
	end
	
	def process_page(params)
		Msg::debug("#{self.class}.#{__method__}()")
		
		uri = params.fetch(:uri,nil) or raise 'отсутствует URI'
		page = params.fetch(:page,nil) or raise 'отсутствует страница'
		rule = params.fetch(:rule,nil) or raise 'отсутствует правило'
		
		processor_name = rule.get_processor(uri)
		page = rule.send(processor_name, page)
	end
	
	# возвращает хеш { src => nil }, ключи заполняются в процессе загрузки картинок; ссылки ремонтируются непосредственно
	# перед загрузкой. Хэш используется для "локализации" html-страницы.
	def load_images(params)
		Msg::debug(" #{self.class}.#{__method__}()")
		
		links = params[:page].scan(/<img\s+src\s*=\s*['"](?<image_uri>[^'"]+)['"][^>]*>/).map { |lnk| lnk.first }
		
		links_hash = {}
		
		links.each { |lnk| links_hash[lnk] = nil }
		
		links_hash.each_key { |lnk|
			links_hash[lnk] = repair_uri(params[:uri], lnk)
		}
		
		links_hash.each_pair { |orig_link,full_link|
			begin
				image_data = load_page(uri: full_link)
				image_file = File.join(@@images_dir,"#{rand(10000)}.jpg")
				File.write(image_file,image_data)
				Msg::debug("загружено изображение (#{full_link}")
			rescue => e
				Msg::debug("ошибка загрузки изображения (#{full_link})")
				image_file = nil
			end
			
			links_hash[orig_link] = image_file
		}
		
		links_hash
	end
	
	def repair_uri(base_uri, uri, opt={debug:false})
		#Msg::debug("#{self.class}.#{__method__}()")
		
		in_debug = opt[:debug]

		base_uri = URI(base_uri)
		
			Msg::debug("base_uri: #{base_uri}") if in_debug
		
		array_mode = uri.is_a?(Array)
		
			Msg::debug("array_mode: #{array_mode}") if in_debug
		
		uri = [uri] if not array_mode
		
			Msg::debug("uri: #{uri}") if in_debug
		
		uri = uri.map { |one_uri|
			one_uri = one_uri.strip
				Msg::debug("one_uri: #{one_uri}") if in_debug
			one_uri = one_uri.gsub(/\/+$/,'')
				Msg::debug("one_uri: #{one_uri}") if in_debug
			one_uri = URI(one_uri)
				Msg::debug("one_uri: #{one_uri}") if in_debug
			one_uri.host = base_uri.host if one_uri.host.nil?
				Msg::debug("one_uri: #{one_uri}") if in_debug
			one_uri.scheme = base_uri.scheme if one_uri.scheme.nil?
				Msg::debug("one_uri: #{one_uri}") if in_debug
			one_uri.to_s
		}
		
			Msg::debug("uri: #{uri}") if in_debug
		
		uri = uri.first if not array_mode
		
			Msg::debug("uri: #{uri}") if in_debug
		
		return uri
	end
	
	def save_results(page, media)
		Msg::debug("#{self.class}.#{__method__}()")
	end
end


class Msg
	#~ def self.debug(msg)
		#~ puts msg
	#~ end
	
	def self.debug(msg, params={})
		params.fetch(:nobr,false) ? print(msg) : puts(msg)
		#puts "#{msg}, nobr: #{params.fetch(:nobr,false)}"
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

book.page_limit = 1

book.prepare
book.save

puts ''
puts book.inspect
