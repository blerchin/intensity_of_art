
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
	result img
end

def avg_data( img )
	pixel = img.thumbnail(1,1).pixel_color(0,0)
	color = pixel.to_color(Magick::AllCompliance, false, 8, false)
	intensity = img.thumbnail(1,1).pixel_color(0,0).intensity()
	return {  "color" => color , "intensity" => intensity }
end



def scrape_artforum_url( address)

	artforum_listing = Scraper.define do
	  process "div p[class] b", :artist=>:text
 	  process "div p[class]", :title=>:text
	  process "div p strong", :gallery=>:text
	  process "div p", :dates=>:text
	  process "div div p:not(.address)", :description=>:text 
	  process "div div div div a img",  :image=>"@src"
		  		
	
	  result :artist, :title , :gallery,  :dates, :description, :parsed_image
	end
	
	artforum = Scraper.define do
	  array :exhibitions
	
	  process "li div",
			  :exhibitions => artforum_listing
	
	  result :exhibitions
	end


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
#listings.each{ |n| puts n.last }
	
# use built-in CSV class to convert array to csv string and put to file

temp = File.open("temp.csv","w")

listings_csv = CSV.dump(listings)

# the text still has lots of fugly HTML encoded chars
h_coder = HTMLEntities.new
decoded_csv = h_coder.decode(listings_csv)

temp.puts decoded_csv

temp.close	


