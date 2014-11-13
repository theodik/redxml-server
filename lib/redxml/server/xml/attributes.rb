module RedXML
  module Server
    module XML
      # Class represents XML attributes of a certain node
      class Attributes
        attr_accessor :attrs, :node

        def initialize(node, attrs=false)
          key      = ""
          value    = ""
          attrs  ||= {}
          @attrs   = attrs
          @node    = node
        end

        def get_attr(name)
          result = nil
          @attrs.each do |key, value|
            result = value if key == name
          end
          result
        end

        def length
          @attrs.length
        end
      end
    end
  end
end
