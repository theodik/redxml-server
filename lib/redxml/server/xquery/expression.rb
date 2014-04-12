module RedXML
  module Server
    module XQuery
      module Expressions
        # rubocop:disable LineLength
        autoload :AbbrevForwardStep,    'redxml/server/xquery/expressions/abbrev_forward_step'
        autoload :ComparisonExpr,       'redxml/server/xquery/expressions/comparison_expr'
        autoload :CompAttrConstructor,  'redxml/server/xquery/expressions/comp_attr_conrstructor'
        autoload :DeleteExpr,           'redxml/server/xquery/expressions/delete_expr'
        autoload :DirElemConstructor,   'redxml/server/xquery/expressions/dir_elem_constructor'
        autoload :DummyExpr,            'redxml/server/xquery/expressions/dummy_expr'
        autoload :ElemConstructor,      'redxml/server/xquery/expressions/elem_constructor'
        autoload :FLWORExpr,            'redxml/server/xquery/expressions/flwor_expr'
        autoload :ForLetClause,         'redxml/server/xquery/expressions/for_let_caluse'
        autoload :FunctionCall,         'redxml/server/xquery/expressions/function_call'
        autoload :InsertExpr,           'redxml/server/xquery/expressions/insert_expr'
        autoload :OrderByClause,        'redxml/server/xquery/expressions/order_by_clause'
        autoload :Predicate,            'redxml/server/xquery/expressions/predicate'
        autoload :RelativePathExpr,     'redxml/server/xquery/expressions/relative_path_expr'
        autoload :ReturnExpr,           'redxml/server/xquery/expressions/return_expr'
        autoload :StepExpr,             'redxml/server/xquery/expressions/step_expr'
        autoload :VarRef,               'redxml/server/xquery/expressions/var_ref'
        autoload :WhereClause,          'redxml/server/xquery/expressions/where_clause'
        # rubocop:enable LineLength

        def self.reduce(node, content = nil)
          content = node.content if content.nil?

          node.children.each do |n|
            if !n.content.empty? && n.content == content
              return reduce(n, content)
            end
          end

          return node.parent if node.name == 'text'
          node
        end

        def self.checked_reduce(node, preffered_type, content = nil)
          content = node.content if content.nil?
          return node if node.name == preffered_type

          node.children.each do |n|
            if !n.content.empty? && n.content == content
              return checked_reduce(n, preffered_type, content)
            end
          end

          return node.parent if node.name == 'text'
          node
        end

        class Expression
          def self.create(node)
            reduced_node = Expressions.reduce(node)
            exprs = %w(FLWORExpr RelativePathExpr VarRef \
                       DirElemConstructor DelteExpr InsertExpr)
            if exprs.include?(reduced_node.name)
              klass = Expressions.const_get(reduced_node.name)
              klass.new(reduced_node)
            else
              Expressions::Expression.new(reduced_node)
            end
          end

          def initialize(node)
            @node = node
          end

          def type
            @node.name
          end

          def text
            @node.content
          end

          protected

          attr_reader :node
        end
      end
    end
  end
end
