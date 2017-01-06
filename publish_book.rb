require 'json'
require 'prawn'
require 'rubygems'


def publish_book( af_details, dir )
	Prawn::Document.generate("temp.pdf",
							 :page_size 	=> [324, 513], #lulu pocket full bleed
							 :page_layout 	=> :portrait,
							 :margin 		=> 0
	) do
	register_fonts
	
	Dir.chdir( dir )
	sorted_af_details = af_details.sort{|x,y| x["intensity"] <=> y["intensity"] }
	
	sorted_af_details.each { |l|
		canvas do 
			image l["image"], 	:at => bounds.top_left,
								:height => bounds.height - 72
			font("FuturaBI")
			font_size(24)
				text_box l["color"], 
					:at => [ (bounds.right - 166), (bounds.bottom + 48) ],
					:width => 144,
					:height => 36,
					:align => :right,
					:font_size => 24
		end
		
		start_new_page
		}
	
	end		


end

def register_fonts
	working_dir = Dir.getwd
	font_families.update("FuturaBI" => {
	:normal => working_dir + "/fonts/FutuBdIt.ttf"
	})
	
	end


def get_details_from_json( filename )
	json = File.open( filename, 'r')
	details = JSON.load( json )
	puts "json details parsed successfully"
	return details
	end


