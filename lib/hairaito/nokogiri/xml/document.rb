module Hairaito
  module Nokogiri
    module XML
      module Document

        # Highlights text snippets in document
        #
        # @param snippets [Array<String>] text variants to be highlighted
        # @param options [Hash] custom highlighting options
        # @return [Nokogiri::XML::Document] self document for chaining
        def highlight(snippets, options = {})
          highlighting_defaults(options)
          snippet_parts_to_wrap = []
          prepare_snippets(snippets).each do |snippet|
            highlighting_base.traverse_by_text(snippet, @hl_opts[:boundaries]) do |snippet_container, snippet_offset|
              start_node, start_inner_index = snippet_container.text_node_by_position(snippet_offset.first)
              start_range = start_node.text_range_by_index(start_inner_index, snippet.length)
              snippet_parts_to_wrap << {part: start_node, range: start_range, starting: true}

              # If start node contains only part of snippet
              if snippet.length > start_range.size
                end_node, end_inner_index = snippet_container.text_node_by_position(snippet_offset.last - 1)
                end_range = end_node.text_range_by_index(end_inner_index)
                snippet_parts_to_wrap += snippet_container.text_nodes_between(start_node, end_node).map do |node|
                  {part: node, range: 0..(node.text.length - 1)}
                end
                snippet_parts_to_wrap << {part: end_node, range: end_range}
              end
            end
          end
          snippet_parts_to_wrap.group_by{|part_data| part_data[:part]}.each do |part, parts_collection|
            part.highlight_by_ranges(parts_collection.map{|p| p.except(:part)}, @hl_opts)
          end
          numerate_snippet_parts if @hl_opts[:numeration][:attr].present?
          self
        end

        private

        def highlighting_defaults(options)
          @hl_base = nil
          @hl_opts = {
              highlight_base: {
                  selector: 'body',
                  content_wrapper: '',
                  content_wrapper_class: 'highlighting-base',
              },
              snippet: {
                  part_wrapper: 'span',
                  part_wrapper_class: 'snippet-part',
                  starting_part_class: 'snippet-start',
              },
              numeration: {
                  attr: 'data-snippet-id',
                  prefix: '',
                  suffix: '',
                  start_with: 0,
              },
              boundaries: {},
          }.deep_merge(options).with_indifferent_access
        end

        def highlighting_base
          return @hl_base if @hl_base.present?
          base = at(@hl_opts[:highlight_base][:selector])
          raise ArgumentError.new('Document does not contain highlighting base element!') if base.blank?
          if @hl_opts[:highlight_base][:content_wrapper].present?
            wrapper = create_element("#{@hl_opts[:highlight_base][:content_wrapper]}",
                                     class: "#{@hl_opts[:highlight_base][:content_wrapper_class]}")
            base.children.each{|child| child.parent = wrapper}
            wrapper.parent = base
            @hl_base = wrapper
          else
            @hl_base = base
          end
          @hl_base
        end

        # Longer snippets must go first due to situations with snippets overlapping
        # Example: ['abc', 'abcdef'],
        # without sorting this produces highlighting artifacts like shorter snippet duplication in result nodes
        def prepare_snippets(snippets)
          snippets.uniq.sort_by{|snippet| snippet.length}.reverse
        end

        def numerate_snippet_parts
          selector = @hl_opts[:snippet][:part_wrapper_class].gsub(/\s+/, ' ').split(' ').map{|cl| ".#{cl}"}.join('')
          index = @hl_opts[:numeration][:start_with] - 1
          css(selector).each do |part|
            index += 1 if part[:class].split(' ').include?(@hl_opts[:snippet][:starting_part_class])
            part[@hl_opts[:numeration][:attr]] = "#{@hl_opts[:numeration][:prefix]}#{index}#{@hl_opts[:numeration][:suffix]}"
          end
        end

      end
    end
  end
end