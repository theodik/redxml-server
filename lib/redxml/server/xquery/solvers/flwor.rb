module RedXML
  module Server
    module XQuery
      module Solvers
        class FLWOR
          def initialize(path_solver, update_solver)
            @path_solver = path_solver
            @for_let_clause_solver = ForLetClause.new(@path_solver)
            @where_clause_solver = WhereClause.new(@path_solver)
            @order_clause_solver = OrderClause.new(@path_solver)
            @return_expr_solver = ReturnExpr.new(@path_solver, update_solver)
          end

          def solve(expression)
            @contexts = [XQuerySolverContext.new]
            @results = nil
            # iterate over all expression parts sequentially
            expression.parts.each do |part|
              process_flwor_part(part)
            end
            @results
          end

          private

          def process_flwor_part(part)
            case part.type
            when 'ForClause', 'LetClause'
              @contexts.each do |context|
                @for_let_clause_solver.solve(part, context)
              end
              flatten_contexts
            when 'WhereClause'
              new_contexts = []
              @contexts.each do |context|
                @where_clause_solver.solve(part, context)
                new_contexts << context if context.passed
              end
              @contexts = new_contexts
            when 'OrderByClause'
              @order_clause_solver.solve(part, @contexts)
            when 'ReturnExpr'
              @results = @return_expr_solver.solve(part, @contexts)
            else
              fail StandardError, "not possible flwor part type: #{part.type}"
            end
          end

          def flatten_contexts(context = nil)
            if context.nil?
              ctxs = @contexts
              @contexts = []
              ctxs.each do |ctx|
                if ctx.final
                  @contexts << ctx
                else
                  @contexts.concat(flatten_contexts(ctx))
                end
              end
              return
            end

            context.cycles.map do |ctx|
              if ctx.final
                ctx
              else
                flatten_contexts(ctx)
              end
            end
          end
        end
      end
    end
  end
end
