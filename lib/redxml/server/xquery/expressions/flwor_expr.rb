module RedXML
  module Server
    module XQuery
      module Expressions
        class FLWORExpr < Expression
          def initialize(node)
            super(node)
            # scan for clauses and prepare parts this time
            @children = []
            was_return = false
            node.children.each do |child|
              if child.name == 'TOKEN' && child.content == 'return'
                was_return = true
                next
              end

              if !was_return
                case child.name
                when 'ForClause', 'LetClause'
                  @children << ForLetClause.new(child)
                when 'WhereClause'
                  @children << WhereClause.new(child)
                when 'OrderByClause'
                  @children << OrderByClause.new(child)
                else
                  fail StandardError, "such FLWOR expression " \
                    "not recognised: #{child.name}"
                end
              else
                @children << ReturnExpr.new(child)
              end
            end
          end

          def parts # rubocop:disable TrivialAccessors
            # FIXME: style: why trivial accessor if different names?
            @children
          end
        end
      end
    end
  end
end
