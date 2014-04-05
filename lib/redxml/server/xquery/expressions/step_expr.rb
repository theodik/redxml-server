module RedXML
  module Server
    module XQuery
      module Expressions
        class StepExpr < Expression # encapsulates some functions, elements
          attr_reader :step_type, :value, :predicates

          # step type
          ORDINARY = :ORDINARY
          RECURSIVE = :RECURSIVE
          STARTING = :STARTING

          # FIXME: START => STARTING?
          def initialize(node, step_type = START)
            super(node)

            @step_type = step_type

            @value = nil
            @predicates = []

            # determine specific step type
            sub_node = node.children[0]
            sub_node.children.each do |child|
              case child.name
              when 'PrimaryExpr' # this will probably be a function or variable
                reduced_node = Expressions.reduce(child)
                if reduced_node.name == 'VarRef'
                  @value = VarRef.new(reduced_node)
                elsif reduced_node.name == 'FunctionCall'
                  @value = FunctionCall.new(reduced_node)
                else
                  fail 'not implemented'
                end
              when 'ForwardStep'
                if child.children[0].name != 'AbbrevForwardStep'
                  fail 'not implemented'
                end
                # probably AbbrevForwardStep - element or attribute name
                @value = AbbrevForwardStep.new(child.children[0])
              when 'PredicateList'
                child.children.each do |pred|
                  @predicates << Predicate.new(pred)
                end
              else
                fail "not implemented: #{child.name}"
              end
            end
          end
        end
      end
    end
  end
end
