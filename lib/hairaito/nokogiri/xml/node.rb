module Hairaito
  module Nokogiri
    module XML
      module Node

        def text_nodes
          result_nodes = []
          traverse do |node|
            result_nodes << node if node.text?
          end
          result_nodes
          ::Nokogiri::XML::NodeSet.new(document, result_nodes)
        end

        def text_nodes_between(start_node, end_node)
          nodes = text_nodes
          indexes = [nodes.index(start_node), nodes.index(end_node)]
          raise ArgumentError.new('Node must contain both start and end nodes!') if indexes.compact.count < 2
          # Start and end nodes are equals or are neighbours
          return [] if indexes.last - indexes.first < 2
          result_nodes = nodes.slice((indexes.first + 1)..(indexes.last - 1))
          ::Nokogiri::XML::NodeSet.new(document, result_nodes)
        end

        def traverse_by_text(text, exclude_ancestors = true)
          excluded = []
          result_nodes = []
          traverse do |node|
            next if node.is_a?(::Nokogiri::XML::Text)
            next if node.in?(excluded)
            if node.text.include?(text)
              result_nodes << node
              excluded += node.ancestors if exclude_ancestors
            end
          end
          result_nodes
        end

        def text_node_by_position(in_text_position)
          text_nodes.each do |node|
            # Node does not contain parent_index
            if node.text.length - 1 < in_text_position
              in_text_position -= node.text.length
              next
            end
            return node, in_text_position
          end
          raise ArgumentError.new('Inner index is out of range!')
        end

        def highlight_by_range(range)
          prefix = range.first > 0 ? text[0..(range.first - 1)]: ''
          suffix = range.last < text.length - 1 ? text[(range.last + 1)..(text.length - 1)]: ''
          for_wrapping = text[range]
          new_contents = "#{prefix}#{document.highlight_snippet_part(for_wrapping)}#{suffix}"
          replace(new_contents)
        end

        def text_range_by_index(index, demand_length = nil)
          demand_length.present? ? index..[text.length - 1, index + demand_length - 1].min : 0..index
        end

      end
    end
  end
end
