module RedXML
  module Server
    module XQuery
      module Expressions
        class VarRef < Expression
          attr_reader :var_name

          def initialize(node)
            super(node)
            @var_name = node.children[1].content
          end
        end
      end
    end
  end
end
