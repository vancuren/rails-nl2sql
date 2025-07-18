module Rails
  module Nl2sql
    module Providers
      class Base
        def initialize(**_opts); end

        def complete(prompt:, **_params)
          raise NotImplementedError, "Providers must implement #complete"
        end
      end
    end
  end
end
