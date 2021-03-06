module RedXML
  module Server
    module XQuery
      class QueryStringError < StandardError
      end

      class TypeError < QueryStringError
      end

      class NotSupportedError < StandardError
      end
    end
  end
end
