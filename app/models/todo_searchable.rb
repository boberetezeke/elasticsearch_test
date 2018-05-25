require_relative 'elastic_search_for_sunspot'

module TodoSearchable
  def self.included(base)
    base.include(Elasticsearch::Model)
    base.include(Elasticsearch::Model::Callbacks)

    base.include(ElasticSearchForSunspot::InstanceMethods)
    base.extend(ElasticSearchForSunspot::ClassMethods)

    base.es_searchable do
      text :todo
      text :todo_surround, using: :surround_todo
    end
  end

  def surround_todo
    "<<#{todo}>>"
  end
end