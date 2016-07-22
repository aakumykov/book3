def CreateEpub (output_file, bookArray, metadata)
		Msg.info "#{__method__}('#{output_file}')"
		
		puts "\n=================================== bookArray =================================="
		ap bookArray
		
		# arg = { :bookArray, :metadata }
		def MakeNcx(arg)
			Msg.debug "#{__method__}()"
			
			# arg = { :bookArray, :depth }
			def MakeNavPoint(bookArray, depth)
				
				navPoints = ''
				
				bookArray.each { |item|
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
	<content src='#{@text_dir}/#{item[:file_name]}'/>

	<navPoint id='#{id}' playOrder='#{depth}'>
		<navLabel>
			<text>#{item[:title]}</text>
		</navLabel>
		<content src='#{@text_dir}/#{item[:file_name]}'/>
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
		<content src='#{@text_dir}/#{item[:file_name]}'/>
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


			nav_data = MakeNavPoint(arg[:bookArray],0)
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
		
		# arg = { :bookArray, :metadata }
		def MakeOpf(arg)
			Msg.debug "#{__method__}()"
			
			# manifest - опись содержимого
			def makeManifest(bookArray)
				Msg.debug "#{__method__}()"
				
				output = ''
				
				bookArray.each{ |item|
					id = 'opf_' + Digest::MD5.hexdigest(item[:id])
					output += <<MANIFEST
	<item href='#{@text_dir}/#{item[:file_name]}' id='#{id}'  media-type='application/xhtml+xml' />
MANIFEST
					output += self.makeManifest(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
			
			# spine - порядок пролистывания
			def makeSpine(bookArray)
				Msg.debug "#{__method__}()"
				
				output = ''

				bookArray.each { |item|
					id = 'opf_' + Digest::MD5.hexdigest(item[:id])
					output += "\n\t<itemref idref='#{id}' />";
					output += self.makeSpine(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
			
			# guide - это семантика файлов
			def makeGuide(bookArray)
				Msg.debug "#{__method__}()"
				
				output = ''
				
				bookArray.each { |item|
					output += "\n\t<reference href='#{@text_dir}/#{item[:file_name]}' title='#{item[:title]}' type='text' />"
					output += self.makeGuide(item[:childs]) if not item[:childs].empty?
				}
				
				return output
			end
				
			manifest = makeManifest(arg[:bookArray])
			spine = makeSpine(arg[:bookArray])
			guide = makeGuide(arg[:bookArray])

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
		ncxData = MakeNcx(:bookArray => bookArray,:metadata => metadata)
		opfData = MakeOpf(:bookArray => bookArray,:metadata => metadata)
		
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
