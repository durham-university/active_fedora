module ActiveFedora
  module PropertyFilters
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :RelevanceOrderFilter
    end
  end
end
