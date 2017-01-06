class Struct
  def to_map
    map = Hash.new
    self.members.each { |m| map[m] = self[m] }
    map
  end

  def to_json(*a)
    to_map.to_json(*a)
  end
end


def get_img( fname )
	img = Magick::Image::read(fname).first
	return img
end

def avg_data( img )
	pixel = img.thumbnail(1,1).pixel_color(0,0)
	color = pixel.to_color(Magick::AllCompliance, false, 8, false)
	intensity = img.thumbnail(1,1).pixel_color(0,0).intensity()
	return {  :color => color , :intensity => intensity }
end

def get_page_count( address )
	html = Net::HTTP.get( URI(address) )
	parser = XML::HTMLParser.string( html, :encoding => XML::Encoding::ISO_8859_1, :base_uri => "http://artforum.com", 
								:options => XML::HTMLParser::Options::RECOVER )
	xml_doc = parser.parse
	
	page_nav = xml_doc.find("//div[@class='Controls']/div[@class='Nav']/ul/li", 'xlink:http://www.w3.org/1999/xhtml')
	pages = Array.new
	page_nav.each do |n|
		unless n['class'] == 'last' then pages << n.child.content end
	end
	
	last = pages.last.to_i - 1
	
	
	return last
end


def scrape_artforum_url_2( address)

	# grab html as a string from address provided
	html = Net::HTTP.get( URI(address) )

	#ec = Encoding::Converter.new("iso-8859-15", "utf-8") 
	#html = ec.convert(html).dump 
	
	parser = XML::HTMLParser.string( html, :encoding => XML::Encoding::ISO_8859_1, :base_uri => "http://artforum.com", 
								:options => XML::HTMLParser::Options::RECOVER )
	xml_doc = parser.parse
	
	# define what a listing looks like
	unless defined? Struct::WebListing then Struct.new("WebListing", :title, :gallery, :dates, :image) end
	
	#create an array to hold all the listings
	listings = Array.new
	
	#get the li node of each listing into an XML::Node::Set
	#ugly auto-generated XPath, cause artforum's site has 0 semantics
	
	xml_listings = xml_doc.root.find_first("//div[@class='Listings']/ul", 'xlink:http://www.w3.org/1999/xhtml')
#	puts xml_listings
	xml_listings.find('li').each{ |n|


		if( n.children?) then
			
			l = Struct::WebListing.new
			
			img_src = n.find('.//a/img').first
			l[:image] = unless img_src.nil? then img_src["src"] end
			
			gallery = n.find(".//div[@class='Location']/p/strong").first
			l[:gallery] = unless gallery.nil? then gallery.content end
			
			title = n.find(".//div[@class='Right']/p[@class='Title']").first
			l[:title] = unless title.nil? then title.content end
			
			dates = n.find(".//div[@class='Right']/p[2]").first
			l[:dates] = unless dates.nil? then dates.content end
			
			listings << l
	
		end	
	}
	
	
	return listings
end




def complete_af_img_src( url )
		complete_src = 'http://artforum.com/' + url #[/(\/&quot;\/)(.*)(\/&quot;)/,2]
	
		#popup url is always the same, + '_popup' before extension
		popup_src = complete_src.gsub(/(.*)[\.](.*)/, '\1_popup.\2')
		
		# popup image doesn't always exist, so we check the HTTP response code to decide 
		# which image to retrieve
		response = Net::HTTP.get_response( URI( popup_src) ).code
		if  response.to_s == "200" then
			puts "popup image exists"
			img = get_img( popup_src )
		else
			img = get_img(complete_src)
		end
		
		return img
end






