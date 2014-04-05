module RedXML
  module Server
    module XQuery
      module Expressions
        class CompAttrConstructor < Expressions
          attr_reader :attr_name, :attr_value

          def initialize(node)
            super(node)

            @attr_name = node.children[1].content
            @attr_value = Expressions.reduce(node.children[3])
            if @attr_value.name == 'StringLiteral'
              @attr_value = @attr_value.content[1..-2]
            else
              @attr_value = @attr_value.content
            end
          end
        end
      end
    end
  end
end
