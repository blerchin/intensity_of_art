
require 'rubygems'
require 'net/http'
require 'RMagick'
require 'scrapi'
require 'csv'
require 'htmlentities'




links = Scraper.define do
   process "a[href]", :href=>"@href"
   result :href
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



def scrape_artforum_url( address)
	
	# define our template for items within each block
	artforum_listing = Scraper.define do
	  process "div p[class] b", :artist=>:text
 	  process "div p[class]", :title=>:text
	  process "div p strong", :gallery=>:text
	  process "div p", :dates=>:text
	  process "div div p:not(.address)", :description=>:text 
	  process "div div div div a img",  :image=>"@src"
		  		
	  result :artist, :title , :gallery,  :dates, :description, :image
	end

	# define what a block looks like
	artforum = Scraper.define do
	  array :exhibitions
	
	  process "li div",
			  :exhibitions => artforum_listing
	
	  result :exhibitions
	end

	# grab html as a string from address provided
	html = Net::HTTP.get( URI(address) )

	# scrAPI does not support European encodings, or artists with 'pretentious' European names
	ec = Encoding::Converter.new("iso-8859-15", "utf-8") 
	html = ec.convert(html).dump 

	# do the scrAPI thang
	page_listings = artforum.scrape(html)
	return page_listings
end

listings = Array.new

# range needs to be set manually to cover the number of active pages
(0 .. 3).each{ |n|
	pl = scrape_artforum_url("http://artforum.com/guide/country=US&place=New%20York&page_id=#{n}&show=scheduled")
	pl.each{ |o|
		listings << o
		}
	puts "page #{n} scraped successfully"

	}
	
# time for ImageMagick	
# first we create a new data structure to hold scraped info plus calculated image metadata
Struct.new("Listing", :artist, :title, :gallery, :dates, :description, :image, :intensity, :color)
complete_listings = Array.new #and an array to hold that data

listings.each{ |n| src = n[:image]
	if( src.class == String) then
		complete_src = 'http://artforum.com/' + src[/(\/&quot;\/)(.*)(\/&quot;)/,2]
		
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
		
		#convert to grayscale
		bw_img = img.quantize( 256, Magick::GRAYColorspace, Magick::NoDitherMethod, 0, false)
		
		#make a meaningful filename
		local_src = "saved_images/"+ n[:title].gsub(/\s/,'-').gsub(/[^-a-zA-Z0-9]/,'') + ".png"
		
		#calculate ImageMagick values
		bw_img.write( local_src )
		img_data = avg_data( bw_img )

		# manually copy values from old struct to the new one, which includes image data
		n2 = Struct::Listing.new( n[:artist], n[:title], n[:gallery], n[:dates],
								  n[:description], local_src, img_data[:intensity], img_data[:color] )
		puts " #{img_data[:intensity]} : #{n2[:gallery]}"
		
		complete_listings << n2
	end
	 }
	
# use built-in CSV class to convert array to csv string and put to file

temp = File.open("temp.csv","w")

listings_csv = CSV.dump(complete_listings)

# the text still has lots of fugly HTML encoded chars
h_coder = HTMLEntities.new
decoded_csv = h_coder.decode(listings_csv)

temp.puts decoded_csv

temp.close	


