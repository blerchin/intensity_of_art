
require 'rubygems'
require 'net/http'
require 'RMagick'
require 'json'
require 'prawn'
require 'xml'

load 'scraper_actions.rb'
load 'publish_book.rb'





todays_date = Time.now.strftime("%Y_%m_%d")

listings = Array.new

pages = get_page_count("http://artforum.com/guide/country=US&place=New%20York&page_id=0&show=active")
# range needs to be set manually to cover the number of active pages
(0..pages).each{ |n|
	pl = scrape_artforum_url_2("http://artforum.com/guide/country=US&place=New%20York&page_id=#{n}&show=active")
	pl.each{ |o|
		listings << o
		}
	puts "page #{n} scraped successfully"

	}
	
# time for ImageMagick	
# first we create a new data structure to hold scraped info plus calculated image metadata

class Listing < Struct.new(:title, :gallery, :dates, :image, :intensity, :color); end

complete_listings = Array.new #and an array to hold that data

start_dir = Dir.pwd
unless File::directory?( todays_date) then
	image_loc = Dir::mkdir( todays_date, )
	end
	
Dir.chdir( todays_date )

listings.each_with_index{ |n,i| 
	src = n[:image]
	if( String == src.class ) then
		img = complete_af_img_src( src )
		
		#convert to grayscale
		bw_img = img.quantize( 256, Magick::GRAYColorspace, Magick::NoDitherMethod, 0, false)
		
		local_src = i.to_s+".png"
		
		#calculate ImageMagick values
		bw_img.write( local_src )
		img_data = avg_data( bw_img )

		# manually copy values from old struct to the new one, which includes image data
		n2 = Listing.new( n[:title], n[:gallery], n[:dates],
				 local_src, img_data[:intensity], img_data[:color] )
		puts " #{img_data[:intensity]} : #{n2[:gallery]}"
		
		complete_listings << n2
	end
	 }
	 
#Since we are no longer using ID, let's ditch CSV and use JSON
json = File.new( todays_date + ".json", "w")
json.puts JSON.pretty_generate( complete_listings )
json.close

Dir.chdir( start_dir)

# this is a bit convoluted, but basically we are using the fact that folders and filenames
# we just created were based on today's date to feed those files into the book publishing
# method
publish_book( get_details_from_json( todays_date + "/" + todays_date + ".json"),
			 todays_date)






	 
=begin	
# use built-in CSV class to convert array to csv string and put to file

csv = File.open(Time.now.getutc.usec.to_s + ".csv","w")

listings_csv = CSV.dump(complete_listings, options = { :write_headers => :true} )

# the text still has lots of fugly HTML encoded chars
h_coder = HTMLEntities.new
decoded_csv = h_coder.decode(listings_csv)

csv.puts decoded_csv

csv.close	
=end




