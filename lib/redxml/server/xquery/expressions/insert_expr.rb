module RedXML
  module Server
    module XQuery
      module Expressions
        class InsertExpr < Expression
          TARGET_INTO_LAST  = :TARGET_INTO_LAST
          TARGET_INTO       = :TARGET_INTO_LAST
          TARGET_INTO_FIRST = :TARGET_INTO_FIRST
          TARGET_BEFORE     = :TARGET_BEFORE
          TARGET_AFTER      = :TARGET_AFTER

          attr_reader :items, :location, :target

          def initialize(node)
            super(node)

            items_node = node.children[2]
            location_node = node.children[4]
            @target_choice = nil

            # determine which one
            case node.children[3].content
            when 'into', 'aslastinto'
              @target = TARGET_INTO_LAST
            when 'asfirstinto'
              @target = TARGET_INTO_FIRST
            when 'before'
              @target = TARGET_BEFORE
            when 'after'
              @target = TARGET_AFTER
            else
              fail 'impossible'
            end

            # can be more then one, attribute, variable with some nodes,
            # node from documents in database, new nodes and text
            @items = determine_expression(items_node)
            @items = [@items] unless @items.kind_of?(Array)
            # can be only one, location in a document
            @location = determine_expression(location_node)
          end

          def determine_expression(node)
            expr = nil
            # should give RelativePathExpr - typically
            reduced_node = Expressions.reduce(node)
            case reduced_node.name
            when 'RelativePathExpr'
              expr = RelativePathExpr.new(reduced_node)
            when 'VarRef'
              expr = VarRef.new(reduced_node)
            when 'ParenthesizedExpr'
              expr = []
              singles = reduced_node.children[1].xpath('./ExprSingle')
              singles.each do |expr_single|
                expr << determine_expression(expr_single)
              end
            when 'CompAttrConstructor'
              expr = CompAttrConstructor.new(reduced_node)
            when 'DirElemConstructor'
              expr = DirElemConstructor.new(reduced_node)
            when 'StringLiteral'
              content = reduced_node.content[1..-2]
              expr = DummyExpr.new('StringLiteral', content)
            else
              fail NotSupportedError, reduced_node.name
            end
            expr
          end
        end
      end
    end
  end
end
