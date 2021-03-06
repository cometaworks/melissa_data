module MelissaData
  module WebSmart
    module Formatters
      def viperize_hash hash
        hash.map { |key, value| { viperize(key.to_s) => value } }.reduce(:merge)
      end

      def viperize(string)
        word = string.to_s.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word.to_sym
      end
    end

    class XMLParser
      include MelissaData::WebSmart::Formatters
      attr_accessor :xml_document

      def initialize(xml)
        @xml_document = xml
      end

      def children?(xml_node)
        xml_node.children.empty?
      end

    end

    class PropertyXMLParser < XMLParser
      include MelissaData::WebSmart::Formatters
      def parse
        parsed_hash = {}
        if expected_retrieved?
          retrieved_fields.each_with_index { |f, i| parsed_hash[f] = { data: field_details[i] } }
          parsed_hash.keys.each { |k| parsed_hash[k] = build_subdictionary(parsed_hash[k][:data]) }
          viperize_hash(parsed_hash)
        end
      end

      def field_details
        record_node.children.map(&:children)
      end

      def build_subdictionary(xml_vals)
        keys = xml_vals.map(&:name)
        vals = xml_vals.map { |v| v.children.first.text unless children? v }
        viperize_hash(keys.zip(vals).to_h)
      end

      def expected_fields
        [ "Building", "CurrentDeed", "CurrentSale", "Lot", "Owner",
          "OwnerAddress", "Parcel", "ParsedPropertyAddress", "PriorSale",
          "PropertyAddress", "RecordID", "Result", "SquareFootage", "Values"]
      end

      def expected_fields?(fields)
        expected_fields == fields.sort
      end

      def record_node
        xml_document.children.first.children.last # its just how they structure it..
      end

      def retrieved_fields
        record_node.children.map(&:name)
      end

      def expected_retrieved?
        expected_fields?(retrieved_fields)
      end
    end
  end
end
