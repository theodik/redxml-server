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
            if try_func.name == 'TextTest'
              return [:TEXT, 'text']
            end

            name = node.children[0].content
            if name == '@'
              [:ATTRIBUTE, node.children[1].content]
            else
              [:ELEMENT, name]
            end
          end
        end
      end
    end
  end
end
