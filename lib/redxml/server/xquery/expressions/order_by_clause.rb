module RedXML
  module Server
    module XQuery
      module Expressions
        class OrderByClause < Expression
          OrderSpec = Struct.new(:expr, :modifier)

          attr_reader :parts

          def initialize(node)
            super(node)

            @parts = []
            order_spec_list = node.children[2]
            order_spec_list.children.each do |order_spec|
              modifier = order_spec.children[1].content
              unless modifier.empty?
                if modifier != 'ascending' && modifier != 'descending'
                  fail "other order modifier than ascending/descending " \
                    "not supported: #{modifier}"
                end
              end

              reduced_order = Expressions.reduce(order_spec.children[0])
              case reduced_order.name
              when 'RelativePathExpr'
                path_expr = RelativePathExpr.new(reduced_order)
                @parts << OrderSpec.new(path_expr, modifier)
              when 'VarRef'
                @parts << OrderSpec.new(VarRef.new(reduced_order), modifier)
              else
                fail "other order expr then RelativePathExpr " \
                  "not supported: #{reduced_order.name}"
              end
            end
          end
        end
      end
    end
  end
end
