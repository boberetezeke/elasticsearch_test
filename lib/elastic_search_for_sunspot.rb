module ElasticSearchForSunspot
  module ClassMethods
    class Index
      attr_reader :sym, :sym_type
      def initialize(sym_type, sym, stored: nil, using: nil, multiple: nil)
        @sym_type = sym_type
        @sym = sym
      end
    end

    class Builder
      def initialize(container_class, ignore_attribute_changes_of: [], unless: nil)
        @container_class = container_class
        @indexes = []
      end

      def text(sym, **hargs)
        indexer(:text, sym, **hargs)
      end

      def string(sym, **hargs)
        indexer(:keyword, sym, **hargs)
      end

      def time(sym, **hargs)
        indexer(:date, sym, **hargs)
      end

      def integer(sym, **hargs)
        indexer(:long, sym, **hargs)
      end

      def float(sym, **hargs)
        indexer(:double, sym, **hargs)
      end

      def indexed_json(object)
        Hash[@indexes.map{|index| [index.sym, object.send(index.sym)] }]
      end

      def create_index
        indexes_array = @indexes
        @container_class.settings do
          mappings do
            indexes_array.each do |index|
              indexes index.sym, {type: index.sym_type.to_s}
            end
          end
        end
      end

      private

      def indexer(sym_type, sym, **hargs)
        @indexes.push(Index.new(sym_type, sym, **hargs))
      end
    end

    def es_searchable(**hargs, &block)
      @builder = Builder.new(self, **hargs)
      @builder.instance_exec(&block)
      @builder.create_index
    end

    def indexed_json(object)
      @builder.indexed_json(object)
    end
  end

  module InstanceMethods
    def as_indexed_json(options={})
      self.class.indexed_json(self)
    end
  end
end

