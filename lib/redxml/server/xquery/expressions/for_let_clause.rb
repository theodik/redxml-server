module RedXML
  module Server
    module XQuery
      module Expressions
        class ForLetClause < Expression
          attr_reader :parts

          # Each for clause can contain more than one ($var in path) parts
          Part = Struct.new(:var_name, :path_expr)

          def initialize(node)
            super(node)

            # generate parts
            @parts = []
            var_node_set = node.xpath('./VarName')
            path_node_set = node.xpath('./ExprSingle')
            var_node_set.each_with_index do |var, index|
              reduced = Expressions.reduce(path_node_set[index])
              if reduced.name != 'RelativePathExpr'
                fail StandardError, "other type not supported: #{reduced.name}"
              end
              @parts << Part.new(var.content, RelativePathExpr.new(reduced))
            end
          end
        end
      end
    end
  end
end
