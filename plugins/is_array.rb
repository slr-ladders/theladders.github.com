module Jekyll
  module Filters
    def is_array(obj)
      obj.kind_of?(Array)
    end
  end
end