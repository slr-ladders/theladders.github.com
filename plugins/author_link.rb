module Jekyll
  module Filters
    def author_link(author)
      if File.exists?("../ourteam/#{author.gsub(' ','').downcase}/index.markdown")
        "<a href=\"/ourteam/#{author.gsub(' ','').downcase}\">#{author}</a>"
      else
        author
      end
    end
  end
end
