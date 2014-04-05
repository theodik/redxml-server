module RedXML
  module Server
    module XQuery
      module Expressions
        class DummyExpr
          attr_reader :type, :text

          def initialize(type, content)
            @type = type
            @text = content
          end

          def parts
            []
          end
        end
      end
    end
  end
end
