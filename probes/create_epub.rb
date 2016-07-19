#!/usr/bin/env ruby
#coding: utf-8
system 'clear'

require 'sqlite3'
require 'securerandom'
require 'awesome_print'


def show_usage
	STDERR.puts "Использование: #{__FILE__} <файл БД> <каталог-источник>"
	exit 1
end

case ARGV.count
when 2
	db_file = ARGV.first
	source_dir = ARGV.last
else
	show_usage
	exit 1
end


class Book

	def initialize(db_file)
		Msg.debug "#{self.class}.#{__method__}()"
		
		@db = SQLite3::Database.new db_file
		@db.results_as_hash = true
		
		@table_name = 'links'
	end

	def get_book_array
		Msg.debug "#{self.class}.#{__method__}()"
		
		def get_toc_items(arg)
			
			list = []
			
			res = @db.prepare("SELECT * FROM #{@table_name} WHERE parent_id=? AND status='processed'").execute(arg[:parent_id])
			
			res.each { |row|
				list << {
					:id => row['id'],
					:parent_id => row['parent_id'],
					:title => row['title'],
					:file => row['file'],
					:uri => row['uri'],
					:childs => self.send(__method__, {parent_id: row['id']})
				}
			}
			
			return list
		end

		return get_toc_items(parent_id: 0)
	end

	def create_epub (output_file, book_array, metadata)
		Msg.info "#{__method__}('#{output_file}')"
		
		#puts "\n=================================== book_array =================================="
		#ap book_array
		
		# arg = { :book_array, :metadata }
		def MakeNcx(arg)
			Msg.debug "#{__method__}()"
			
			# arg = { :book_array, :depth }
			def MakeNavPoint(book_array, depth)
				
				navPoints = ''
				
				book_array.each { |item|
					#puts "===================== item ========================"
					#ap item
					
					id = Digest::MD5.hexdigest(item[:id])
					
					if not item[:childs].empty? then
						
						dir_id = SecureRandom.uuid
					
						navPoints += <<NCX
<navPoint id='#{dir_id}'>
	<navLabel>
		<text>>> #{item[:title]}</text>
	</navLabel>
	<content src='#{@text_dir}/#{item[:file]}'/>

	<navPoint id='#{id}' playOrder='#{depth}'>
		<navLabel>
			<text>#{item[:title]}</text>
		</navLabel>
		<content src='#{@text_dir}/#{item[:file]}'/>
	</navPoint>
NCX
						depth += 1
						
						navPoints += MakeNavPoint(item[:childs], depth)[:xml_tree]
						
						navPoints += <<NCX
</navPoint>
NCX
					else
						navPoints += <<NCX
	<navPoint id='#{id}' playOrder='#{depth}'>
		<navLabel>
			<text>#{item[:title]}</text>
		</navLabel>
		<content src='#{@text_dir}/#{item[:file]}'/>
	</navPoint>
NCX
						depth += 1
					end
				}
				
				return { 
					:xml_tree => navPoints,
					:depth => depth,
				}
			end


			nav_data = MakeNavPoint(arg[:book_array],0)
			metadata = arg[:metadata]

			ncx = <<NCX_DATA
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx version="2005-1" xmlns="http://www.daisy.org/z3986/2005/ncx/">
<head>
	<meta content="FB2BookID" name="dtb:uid"/>
	<meta content="1" name="dtb:#{nav_data[:depth]}"/><!-- depth -->
	<meta content="0" name="dtb:#{nav_data[:depth]}"/><!-- pages count -->
	<meta content="0" name="dtb:#{nav_data[:depth]}"/><!-- max page number -->
</head>
<docTitle>
	<text>#{@metadata[:title]}</text>
</docTitle>
<navMap>
#{nav_data[:xml_tree]}</navMap>
</ncx>
NCX_DATA

			return ncx
		end
		
		# arg = { :book_array, :metadata }
		def MakeOpf(arg)
			Msg.debug "#{__method__}()"
			
			# manifest - опись содержимого
			def makeManifest(book_array)
				Msg.debug "#{__method__}()"
				
				output = ''
				
				book_array.each{ |item|
					id = 'opf_' + Digest::MD5.hexdigest(item[:id])
					output += <<MANIFEST
	<item href='#{@text_dir}/#{item[:file]}' id='#{id}'  media-type='application/xhtml+xml' />
MANIFEST
					output += self.makeManifest(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
			
			# spine - порядок пролистывания
			def makeSpine(book_array)
				Msg.debug "#{__method__}()"
				
				output = ''

				book_array.each { |item|
					id = 'opf_' + Digest::MD5.hexdigest(item[:id])
					output += "\n\t<itemref idref='#{id}' />";
					output += self.makeSpine(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
			
			# guide - это семантика файлов
			def makeGuide(book_array)
				Msg.debug "#{__method__}()"
				
				output = ''
				
				book_array.each { |item|
					output += "\n\t<reference href='#{@text_dir}/#{item[:file]}' title='#{item[:title]}' type='text' />"
					output += self.makeGuide(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
				
			manifest = makeManifest(arg[:book_array])
			spine = makeSpine(arg[:book_array])
			guide = makeGuide(arg[:book_array])

			metadata = arg[:metadata]
			
			opf = <<OPF_DATA
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
	<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
		<dc:identifier id="BookId" opf:scheme="UUID">urn:uuid:#{@metadata[:id]}</dc:identifier>
		<dc:title>#{@metadata[:title]}</dc:title>
		<dc:creator opf:role="aut">#{@metadata[:author]}</dc:creator>
		<dc:language>#{@metadata[:language]}</dc:language>
		<meta name="#{@metadata[:generator_name]}" content="#{@metadata[:generator_version]}" />
	</metadata>
	<manifest>
#{manifest}
		<item href="toc.ncx" id="ncx" media-type="application/x-dtbncx+xml" />
	</manifest>
	<spine toc="ncx">#{spine}
	</spine>
	<guide>#{guide}
	</guide>
</package>
OPF_DATA
			return opf
		end
		
		
		def createZipFile(zip_file, source_path)
			Msg.info "#{__method__}(#{zip_file},#{source_path})"
			Find.find(source_path) do |input_item|
				Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
					virtual_item = input_item.strip.gsub( source_path, '' ).gsub(/^[\/]*/,'')
					next if virtual_item.empty?
					zipfile.add(virtual_item, input_item)
				end
			end
		end
		
		
		# создание дерева каталогов под epub-книгу
		epub_dir = @book_dir + '/' + 'epub'
		meta_dir = epub_dir + '/META-INF'
		oebps_dir = epub_dir + '/OEBPS'
		oebps_text_dir = oebps_dir + '/Text'
		
		#~ begin
			#~ FileUtils.rm_rf(epub_dir)
		#~ rescue
			#~ raise "Не могу удалить '#{epub_dir}' с подкаталогами"
		#~ end
		
		Dir.mkdir(epub_dir) if not Dir.exists?(epub_dir)
		Dir.mkdir(meta_dir) if not Dir.exists?(meta_dir)
		Dir.mkdir(oebps_dir) if not Dir.exists?(oebps_dir)
		Dir.mkdir(oebps_text_dir) if not Dir.exists?(oebps_text_dir)
		
		# создание служебных(?) файлов
		File.open(epub_dir + '/mimetype','w') { |file|
			file.write('application/epub+zip')
		}
		File.open(epub_dir + '/META-INF/container.xml','w') { |file|
			file.write <<DATA
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
	<rootfiles>
		<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
   </rootfiles>
</container>
DATA
		}
		
		# создание и запись NCX и OPF
		ncxData = MakeNcx(:book_array => book_array,:metadata => metadata)
		opfData = MakeOpf(:book_array => book_array,:metadata => metadata)
		
		File.open(epub_dir + '/OEBPS/toc.ncx','w') { |file|
			file.write(ncxData)
		}
		
		File.open(epub_dir + '/OEBPS/content.opf','w') { |file|
			file.write(opfData)
		}
		
		Msg.debug "\n=================================== NCX =================================="
		Msg.debug ncxData
		Msg.debug "\n=================================== OPF =================================="
		Msg.debug opfData
		
		# Перемещаю html-файлы в дерево EPUB
		Dir.entries(@book_dir).each { |file_name|
			File.rename(@book_dir + '/' + file_name, oebps_text_dir + '/' + file_name) if file_name.match(/\.html$/)
		}
		
		# Создаю EPUB-файл
		createZipFile( output_file, epub_dir + '/')
	end

end


class Msg
	#~ def self.debug(msg)
		#~ puts msg
	#~ end
	
	def self.debug(msg)
		puts msg.to_s
	end
	
	def self.green(msg)
		puts msg.to_s.green
	end
	
	def self.grey(msg)
		puts msg.to_s.white
	end
	
	def self.cyan(msg)
		puts msg.to_s.cyan
	end
	
	def self.info(msg)
		puts msg.to_s.blue
	end
	
	def self.notice(msg)
		STDERR.puts msg.to_s.yellow
	end
	
	def self.warning(*msg)
		STDERR.puts "ВНИМАНИЕ:".red
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.red
		}
	end
	
	def self.error(*msg)
		STDERR.puts "ОШИБКА:".black.on_red
		self.prepare_msg(msg).each {|m|
			STDERR.puts m.to_s.black.on_red
		}
	end
	
	private
	
	def self.prepare_msg(*msg)
		msg = msg.flatten.map {|m|
			if m.kind_of? Exception then
				[m.message, m.backtrace]
			else
				m
			end
		}
		msg.flatten
	end
end


book = Book.new(ARGV[0])

book_array = book.get_book_array
	ap book_array

metadata = {
	title: 'Пробный epub-файл',
	author: 'Андрюха Кумыч',
	language: 'ru',
	id: SecureRandom::uuid,
	generator_name: 'book3',
	generator_version: '0.0.1-азъ0',
}

