module RedXML
  module Server
    module XQuery
      module Expressions
        class FunctionCall < Expression
          FunctionParam = Struct.new(:value, :type) do
            # FIXME: Remove constants
            # types
            StringLiteral = :StringLiteral
            IntegerLiteral = :IntegerLiteral
            # types
          end

          attr_reader :function_name, :function_params

          def initialize(node)
            super(node)

            @function_name = node.xpath('./FunctionName')[0].content
            @function_params = []
            node.xpath('./ExprSingle').each do |expr|
              reduced = Expressions.reduce(expr)
              param_content = reduced.content
              if param_content.match(/\A["'].*["']\Z/)
                param_content.gsub!("'", '')
                param_content.gsub!('"', '')
              end
              @function_params << FunctionParam.new(param_content, reduced.name)
            end
          end
        end
      end
    end
  end
end
