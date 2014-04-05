module RedXML
  module Server
    module XQuery
      module Expressions
        class ReturnExpr < Expression
          class ReturnText
            attr_reader :type, :text

            def initialize(text)
              @type = ReturnText
              @text = text
            end
          end

          attr_reader :parts

          def initialize(node)
            super(node)

            @parts = []
            reduced = Expressions.reduce(node)
            case reduced.name
            when 'RelativePathExpr'
              @parts << RelativePathExpr.new(reduced)
            when 'VarRef'
              @parts << VarRef.new(reduced)
            when 'DirElemConstructor'
              @parts << DirElemConstructor.new(reduced)
            when 'DeleteExpr'
              @parts << DeleteExpr.new(reduced)
            when 'InsertExpr'
              @parts << InsertExpr.new(reduced)
            else
              fail NotSupportedError, reduced.name
            end
          end
        end
      end
    end
  end
end
