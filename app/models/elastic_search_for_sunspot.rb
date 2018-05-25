module ElasticSearchForSunspot
  module ClassMethods
    class Index
      attr_reader :sym, :sym_type, :block, :using_sym

      def initialize(sym_type, sym, block, stored: nil, using: nil, multiple: nil)
        @sym_type = sym_type
        @sym = sym
        @block = block
        @using_sym = using
      end
    end

    class Builder
      def initialize(container_class, ignore_attribute_changes_of: [], unless: nil)
        @container_class = container_class
        @indexes = []
      end

      def text(sym, **hargs, &block)
        indexer(:text, sym, **hargs, &block)
      end

      def string(sym, **hargs, &block)
        indexer(:keyword, sym, **hargs, &block)
      end

      def time(sym, **hargs, &block)
        indexer(:date, sym, **hargs, &block)
      end

      def integer(sym, **hargs, &block)
        indexer(:long, sym, **hargs, &block)
      end

      def float(sym, **hargs, &block)
        indexer(:double, sym, **hargs, &block)
      end

      def indexed_json(object)
        Hash[@indexes.map do |index|
          [index.sym,
           index.using_sym ?
             object.send(index.using_sym) :
             (index.block ?
               index.block.call :
               object.send(index.sym))
          ]
        end]
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

      def indexer(sym_type, sym, **hargs, &block)
        @indexes.push(Index.new(sym_type, sym, block, **hargs))
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

