module RedXML
  module Server
    module Database
      class ContextNode

        def initialize(col_env, elem_id)
          @env_col_id = col_env
          @elem_id    = elem_id
          @kb  = RedXML::Server::Transformer::KeyBuilder.build_from_s(col_env)
          @kbe = @kb.key_elem(elem_id)

          @attr = @kbe.attr == elem_id
          @text = elem_id =~ /^[\d:>]+t>(\d)/
        end

        def id
          @kbe.elem_id
        end

        def env_col
          @kb.to_s
        end

        def parent
          env_col = @env_col_id
          elem_id = @kbe.parent
          self.class.new(env_col, elem_id)
        rescue RedXML::Server::Transformer::NoElementError
          nil
        end

        def ==(other)
          self.env_col == other.env_col && self.id == other.id
        end
        alias_method :eql?, :==

        def hash
          [@env_col_id, @elem_id].hash
        end

        def type
          if @attr
            "Attributes"
          elsif @text
            "Text"
          else
            "Node"
          end
        end

        def inspect
          "<LockNode:#{type} env=\"#{env_col}\" elem=\"#{@elem_id}\">"
        end
      end
    end
  end
end
