module Hairaito
  module Nokogiri
    module XML
      module Node

        # @return [Nokogiri::XML::NodeSet] all text nodes, that has self as ancestor
        def text_nodes
          result_nodes = []
          traverse do |node|
            result_nodes << node if node.text?
          end
          result_nodes
          ::Nokogiri::XML::NodeSet.new(document, result_nodes)
        end

        # @return [Nokogiri::XML::Node] first text node within self node
        def first_text_node
          traverse do |node|
            return node if node.text?
          end
          nil
        end

        # @param start_node [Nokogiri::XML::Node] left boundary
        # @param end_node [Nokogiri::XML::Node] right boundary
        # @return [Nokogiri::XML::NodeSet] all text nodes are located between specified boundaries
        def text_nodes_between(start_node, end_node)
          nodes = text_nodes
          indexes = [nodes.index(start_node), nodes.index(end_node)]
          raise ArgumentError.new('Node must contain both start and end nodes!') if indexes.compact.count < 2
          # Start and end nodes are equals or are neighbours
          return [] if indexes.last - indexes.first < 2
          result_nodes = nodes.slice((indexes.first + 1)..(indexes.last - 1))
          ::Nokogiri::XML::NodeSet.new(document, result_nodes)
        end

        # @param base [Nokogiri::XML::Node] root element for search
        # @return [Nokogiri::XML::Node, nil] previous text node within base node or nil if it doesn't exist
        def previous_text(base = document)
          first_text_node = text_nodes.first
          base_text_nodes = base.text_nodes
          if (index = base_text_nodes.index(first_text_node)).blank?
            raise ArgumentError.new('Base must contain self node!')
          end
          return if index == 0
          base_text_nodes[index - 1]
        end

        # @param base [Nokogiri::XML::Node] root element for search
        # @return [Nokogiri::XML::Node, nil] next text node within base node or nil if it doesn't exist
        def next_text(base = document)
          first_text_node = text_nodes.last
          base_text_nodes = base.text_nodes
          if (index = base_text_nodes.index(first_text_node)).blank?
            raise ArgumentError.new('Base must contain self node!')
          end
          return if index == base_text_nodes.count - 1
          base_text_nodes[index + 1]
        end

        # Yields for each match of specified string in child nodes recursively
        #
        # @yieldparam node [Nokogiri::XML::Node] child node contains specified string
        # @yieldparam offset [Array] child text inner offset
        # @param string [String] text for matching
        # @param options [Hash] @see #traverse_by_text_default_options
        # @return [Nokogiri::XML::Node] self node for chaining
        def traverse_by_text(string, options = {}, &block)
          traverse_by_text_defaults(options)
          traverse do |current_node|
            next if current_node.text?

            offset_types = @tbt_opts[:whole_words_only] ? [:inner_word, :boundary_word] : [:simple]
            inner_offsets, boundary_offsets = current_node.matched_offsets(string, offset_types, @tbt_opts)

            # Check words bordered with current inline tag if current node has boundary words
            # abc<span>def<span> or <span>def</span>ghi or abc<span>def</span>ghi
            if current_node.name.in?(@tbt_opts[:inline_tags]) && self != current_node
              if boundary_offsets.try(:first).try(:first) == 0
                previous_node = current_node.previous_text(self)
                boundary_offsets.shift if previous_node.try(:matched_offsets, :any, :ending_word, @tbt_opts).present?
              end
              if boundary_offsets.try(:last).try(:first) == 0
                next_node = current_node.next_text(self)
                boundary_offsets.pop if next_node.try(:matched_offsets, :any, :beginning_word, @tbt_opts).present?
              end
            end

            offsets = (inner_offsets + (boundary_offsets || [])).sort_by{|offset| offset.first}
            if offsets.any?
              offsets.each {|offset| yield(current_node, offset)} if block_given?
              if current_node != self
                # Excludes processed offsets from all ancestors
                ([current_node] + current_node.ancestors).each do |node|
                  pos = node.position_by_text_node(current_node.first_text_node)
                  # Shifts all offsets according to node inner position and excludes from future processing
                  node.exclude_offsets(offsets.map{|offset| [offset.first + pos, offset.last + pos]})
                  # Reaches highlighting base
                  break if node == self
                end
              end
            end
          end
          self
        end

        def position_by_text_node(text_node)
          nodes = text_nodes
          if (index = nodes.index(text_node)) < 0
            raise ArgumentError.new('Self node must contain text_node!')
          end
          return 0 if index == 0
          nodes[0..index - 1].map{|node| node.text}.join('').length
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

        def highlight_by_ranges(ranges, options)
          if options[:snippet][:part_wrapper].blank?
            raise ArgumentError.new('Snippet part wrapper tag is not specified!')
          end
          parts = []
          ranges = ranges.sort_by{|r| r[:range].first}
          ranges.each_with_index do |range_data, index|
            range = range_data[:range]
            parts << (range.first > 0 ? text[0..(range.first - 1)]: '') if index == 0
            snippet_class = range_data[:starting] ? "#{options[:snippet][:starting_part_class]}" : ''
            wrapper = document.create_element("#{options[:snippet][:part_wrapper]}", class: "#{options[:snippet][:part_wrapper_class]} #{snippet_class}")
            wrapper.content = text[range]
            parts << wrapper.to_s
            parts << text[(range.last + 1)..(ranges[index + 1][:range].first - 1)] if index < ranges.count - 1
            parts << (range.last < text.length - 1 ? text[(range.last + 1)..(text.length - 1)]: '') if index == ranges.count - 1
          end
          new_contents = parts.join('')
          replace(new_contents)
        end

        def text_range_by_index(index, demand_length = nil)
          demand_length.present? ? index..[text.length - 1, index + demand_length - 1].min : 0..index
        end

        # @return [Array] self node offsets were already processed
        def excluded_offsets
          @excluded_offsets ||= []
        end

        # @param offsets [Array] self node offsets to be excluded in the future processing
        def exclude_offsets(offsets)
          @excluded_offsets ||= []
          @excluded_offsets += offsets
        end

        def matched_offsets(string, types, options)
          types = [types] unless types.is_a?(Array)
          offsets = []
          types.each do |type|
            offsets << text.to_enum(:scan, build_regexp(string, type, options)).map do
              offset = Regexp.last_match.offset(:text)
              # Only one highlighting per position
              offset unless overlapped_offsets?(excluded_offsets, offset)
            end.compact || []
          end
          return *offsets
        end

        private

        def traverse_by_text_defaults(options)
          @tbt_opts = {
              whole_words_only: true,
              inline_tags: %w(a b i s u basefont big em font img label small span strike strong sub sup tt),
              word_parts: '[а-яА-ЯёЁa-zA-Z\d]',
          }.deep_merge(options).with_indifferent_access
        end

        def build_regexp(string, type = :simple, options)
          string = '.+' if string == :any
          case type.to_sym
            when :simple
              return /(?<text>#{string})/
            when :inner_word
              return /(?<!#{options[:word_parts]}|\A)(?<text>#{string})(?!#{options[:word_parts]}|\Z)/
            when :beginning_word
              return /\A(?<text>#{string})(?!#{options[:word_parts]})/
            when :ending_word
              return /(?<!#{options[:word_parts]})(?<text>#{string})\Z/
            when :boundary_word
              return /(\A(?<text>#{string})(?!#{options[:word_parts]}))|((?<!#{options[:word_parts]})(?<text>#{string})\Z)|(\A(?<text>#{string})\Z)/
          end
        end

        def overlapped_offsets?(offsets_collection, offset_for_check)
          offsets_collection.each do |offset|
            return true if (offset_for_check.first...offset_for_check.last).overlaps?(offset.first...offset.last)
          end
          false
        end

      end
    end
  end
end
