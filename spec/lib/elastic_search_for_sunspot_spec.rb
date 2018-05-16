require 'rails_helper'
require 'elastic_search_for_sunspot'

describe ElasticSearchForSunspot do
  before do
    ActiveRecord::Base.connection.create_table("searchable_objects") do |t|
      t.string      :string_value
      t.integer     :integer_value
      t.float       :float_value
      t.datetime    :datetime_value
      t.boolean     :boolean_value
    end

    Object.module_eval <<-EOT
      class SearchableObject < ActiveRecord::Base
        include Elasticsearch::Model
        include Elasticsearch::Model::Callbacks

        include ElasticSearchForSunspot::InstanceMethods
        extend  ElasticSearchForSunspot::ClassMethods

        #{searchable_text}
      end
    EOT
  end

  after do
    Object.send(:remove_const, :SearchableObject)
    ActiveRecord::Base.connection.drop_table("searchable_objects")
    SearchableObject.__elasticsearch__.delete_index! rescue nil
  end

  context "when using a simple text value" do
    let(:searchable_text) { "es_searchable{ text :string_value }"}
    let(:searchable_object) { SearchableObject.create(string_value: 'test') }

    it "can create an object in the table" do
      expect(searchable_object.as_indexed_json).to eq({string_value: 'test'})
    end

    it "has the correct mappings" do
      searchable_object
      expect(SearchableObject.mappings.to_hash).to eq({
         searchable_object: {
            properties: {
               string_value: {
                   type: 'text'
               }
            }
         }
      })
    end

    it "can be found by the string value in ES" do
      searchable_object
      sleep 1.0
      expect(SearchableObject.search("test").records.to_a).to eq([searchable_object])
    end
  end

  context "when using a simple integer value" do
    let(:searchable_text) { "es_searchable{ integer :integer_value }"}
    let(:searchable_object) { SearchableObject.create(integer_value: 5) }

    it "can create an object in the table" do
      expect(searchable_object.as_indexed_json).to eq({integer_value: 5})
    end

    it "has the correct mappings" do
      searchable_object
      expect(SearchableObject.mappings.to_hash).to eq({
          searchable_object: {
              properties: {
                  integer_value: {
                      type: 'long'
                  }
              }
          }
      })
    end

    it "can be found by the integer value in ES" do
      searchable_object
      sleep 1.0
      expect(SearchableObject.search(5).records.to_a).to eq([searchable_object])
    end
  end

  context "when using a virtual values" do
    let(:searchable_text) { "attr_accessor :virtual_string_value, :virtual_integer_value; es_searchable{ string :virtual_string_value; integer :virtual_integer_value }"}
    let(:searchable_object) { SearchableObject.new.tap{|so| so.virtual_integer_value = 4; so.virtual_string_value = "string"; so.save } }

    it "can create an object in the table" do
      expect(searchable_object.as_indexed_json).to eq({virtual_integer_value: 4, virtual_string_value: 'string'})
    end

    it "has the correct mappings" do
      searchable_object
      expect(SearchableObject.mappings.to_hash).to eq({
        searchable_object: {
          properties: {
            virtual_integer_value: {
                type: 'long'
            },
            virtual_string_value: {
                type: 'keyword'
            }
          }
        }
      })
    end

    it "can be found by the virtual integer value in ES" do
      searchable_object
      sleep 1.0
      expect(SearchableObject.search(4).first.virtual_integer_value).to eq(4)
    end

    it "can be found by the virtual string value value in ES" do
      searchable_object
      sleep 1.0
      expect(SearchableObject.search("string").first.virtual_string_value).to eq('string')
    end
  end
end