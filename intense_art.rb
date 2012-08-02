
require 'rubygems'
require 'net/http'
require 'RMagick'
require 'scrapi'
require 'csv'




html = Net::HTTP.get(URI('http://artforum.com/guide/country=US&place=New%20York&page_id=0&show=scheduled'))

# scrAPI does not support European encodings, or artists with 'pretentious' European names
ec = Encoding::Converter.new("iso-8859-15", "utf-8") 
html = ec.convert(html).dump 

# do the scrAPI thang
listings = artforum.scrape(html)
puts listings.class

# use built-in CSV class to convert array to csv string and put to file
temp = File.open("temp.csv","w")
temp.puts CSV.dump(listings)

temp.close	


artforum_listing = Scraper.define do
  process "div p b", :artist=>:text
  process "div p", :title=>:text
  process "div p", :dates=>:text
  process "div div p", :description=>:text 
  process "div a img",  :image=>"@src"

  result :artist , :title, :dates, :description, :image
end

artforum = Scraper.define do
  array :exhibitions

  process "li div",
          :exhibitions => artforum_listing

  result :exhibitions
end

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
	return {  "color" => color , "intensity" => intensity }
end
