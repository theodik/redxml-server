module RedXML
  module Server
    module XQuery
      module Expressions
        class AbbrevForwardStep < Expression
          attr_reader :value_type, :value_name

          def initialize(node)
            super(node)
            @value_type, @value_name = get_type_and_name(node)
          end

          def type
            path = self.class.name
            index = path.rindex('::')
            if index
              path[(index + 2)..-1]
            else
              path
            end
          end

          private

          def get_type_and_name(node)
            try_func = Expressions.reduce(node)
            if try_func == 'TextTest'
              return [:TEXT, 'text']
            elsif try_func == '@'
              return [:ATTRIBUTE, node.children[1].content]
            else
              return [:ELEMENT, node.children[0].content]
            end
          end
        end
      end
    end
  end
end
