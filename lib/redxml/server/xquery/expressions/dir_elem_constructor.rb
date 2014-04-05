require 'set'

module RedXML
  module Server
    module XQuery
      module Expressions
        class DirElemConstructor < Expression
          def initialize(node)
            super(node)
            @elem_str = nil
          end

          ##
          # Find enclosed path expressions and vars
          # resolve them
          # build string with tags and these resolved results
          # TODO: Solver!
          def get_elem_str(path_solver, context = nil, flwor_solver = nil)
            context ||= XQuerySolverContext.new
            # hash with results
            enclosed_expr_hash = {}

            # find eclosed expressions
            # predicate [not(descendant::EnclosedExpr)] does not work
            enclosed_nodes = node.xpath('.//EnclosedExpr/Expr')
            attr_encl_nodes = Set.new
            exprs = node.xpath('.//DirAttributeValue//EnclosedExpr/Expr')
            exprs.each do |attr_node|
              attr_encl_nodes << attr_node.text
            end

            done_enclosed_nodes = []
            final_elem_str = node.text

            enclosed_nodes.each do |enclosed_node|
              # reduce them
              reduced = Expressions.reduce(enclosed_node)
              reduced_text = reduced.text

              # reduce enclosed nodes so they do not embed each other
              incl = false
              done_enclosed_nodes.each do |done_str|
                if done_str.include?("{#{reduced_text}}")
                  incl = true
                  break
                end
              end
              next if incl

              # if already resolved -> skip
              next if enclosed_expr_hash[reduced_text]

              results = []
              case reduced.name
              when 'VarRef' # enclosed expr VarRef type
                results = context.variables[reduced.children[1].text]
              when 'RelativePathExpr' # enclosed expr RelativePathExpr type
                path_expr = RelativePathExpr.new(reduced)
                results = path_solver.solve(path_expr, context)
              when 'FLWORExpr'
                results = flwor_solver.solve(FLWORExpr.new(reduced))
                enclosed_expr_hash[reduced_text] = [results.join]
                results = nil
              else
                fail NotSupportedError, reduced.name
              end

              enclosed_expr_hash[reduced_text] = results if results

              done_enclosed_nodes << reduced_text
            end

            final_elem_str = node.text
            enclosed_expr_hash.keys.sort.reverse.each do |key|
              elem_str = ''
              attr_str = ''
              results = enclosed_expr_hash[key]
              results.each do |result|
                if result.kind_of?(String)
                  elem_str << result
                  attr_str << result
                else
                  node = path_solver.path_processor.get_node(result)
                  elem_str << node.to_html
                  attr_str << node.content
                end
              end
              final_elem_str.gsub!("=\"{#{key}}\"", "=\"#{attr_str}\"")
              final_elem_str.gsub!("{#{key}}", elem_str)
            end
            final_elem_str
          end

          def nokogiri_node(path_solver, context)
            @elem_str = get_elem_str(path_solver, context) unless @elem_str

            xml_doc = Nokogiri.XML(@elem_str) do |config|
              config.default_xml.noblanks
            end
            xml_doc.root
          end
        end
      end
    end
  end
end
