module RedXML
  module Server
    module XQuery
      module Expressions
        class DeleteExpr < Expression
          attr_reader :location

          def initialize(node)
            super(node)
            # should give RelativePathExpr - typically
            location_node = node.children[2]
            reduced_node = Expressions.reduce(location_node)
            @location = create_expr(reduced_node)
          end

          private

          def create_expr(reduced_node)
            case reduced_node.name
            when 'RelativePathExpr'
              RelativePathExpr.new(reduced_node)
            when 'VarRef'
              VarRef.new(reduced_node)
            else
              fail NotSupportedError, @location.name
            end
          end
        end
      end
    end
  end
end
