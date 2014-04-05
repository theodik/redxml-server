module RedXML
  module Server
    module XQuery
      module Expressions
        # encapsulates Steps
        class RelativePathExpr < Expression
          attr_reader :steps

          def initialize(node)
            super(node)
            @steps = []
            # parse steps and remember // or /
            step_type = StepExpr::STARTING
            node.children.each do |child|
              if child.name == 'TOKEN'
                case child.content
                when '/'
                  step_type = StepExpr::ORDINARY
                when '//'
                  step_type = StepExpr::RECURSIVE
                else
                  fail "impossible, token is #{child.content}"
                end
              else
                @steps << StepExpr.new(child, step_type)
              end
            end
          end
        end
      end
    end
  end
end
