module RedXML
  module Server
    module XQuery
      module Expressions
        class ElemConstructor < Expression
          def initialize(node)
            super(node)
            @elem_str = nil
          end

          ##
          # find enclosed path expressions and vars
          # resolve them
          # build string with tags and these resolved results
          def get_elem_str(path_solver, context)
            # hash with results
            enclosed_expr_hash = {}

            # find eclosed expressions
            enclosed_nodes = node.xpath('.//EnclosedExpr/Expr')
            enclosed_nodes.each do |enclosed_node|
              # reduce them
              reduced = Expressions.reduce(enclosed_node)
              reduced_text = reduced.text
              # if already resolved -> skip
              next if enclosed_expr_hash[reduced_text]
              results = []

              case reduced.name
              when 'VarRef' # enclosed expr VarRef type
                results = context.variables[reduced.children[1].text]
              when 'RelativePathExpr' # enclosed expr RelativePathExpr type
                path_expr = RelativePathExpr.new(reduced)
                solved = path_solver.solve(path_expr, context)
                enclosed_expr_hash[reduced_text] = solved
              else
                fail NotSupportedError, reduced.name
              end

              if results
                result_str = ''
                results.each do |result|
                  node = path_solver.path_processor.get_node(result)
                  result_str << node.to_s
                end
                enclosed_expr_hash[reduced_text] = result_str
              end
            end

            final_elem_str = node.text
            enclosed_expr_hash.each do |key, value|
              final_elem_str.gsub!(key, value)
            end

            final_elem_str
          end

          def nokogiri_node(path_solver, context)
            @elem_str = get_elem_str(path_solver) unless @elem_str

            xml_doc = Nokogiri.XML(node.text) do |config|
              config.default_xml.noblanks
            end
            xml_doc.root
          end
        end
      end
    end
  end
end
