require 'htmlentities'

string = "&amp;Ben&apos;s weird coding bing&eacute;"

coder = HTMLEntities.new
puts coder.decode(string)