module Hairaito
  module Nokogiri
    module XML
      module Document

        def highlight(snippets, options = {})
          highlighting_default_options(options)
          snippets.each do |snippet|
            highlighting_base.traverse_by_text(snippet).each do |snippet_container|
              to_wrap = []
              start_index = snippet_container.text().index(snippet)

              start_node, start_inner_index = snippet_container.text_node_by_position(start_index)
              start_range = start_node.text_range_by_index(start_inner_index, snippet.length)
              to_wrap << [start_node, start_range]

              # If start node contains only part of snippet
              if snippet.length > start_range.size
                end_node, end_inner_index = snippet_container.text_node_by_position(start_index + snippet.length - 1)
                end_range = end_node.text_range_by_index(end_inner_index)
                to_wrap += snippet_container.text_nodes_between(start_node, end_node).map do |node|
                  [node, 0..(node.text.length - 1)]
                end
                to_wrap << [end_node, end_range]
              end

              to_wrap.each do |node_data|
                node_data.first.highlight_by_range(node_data.last)
              end

              snippet_container['class'] = "#{snippet_container['class']} #{@hl_opts[:snippet_container_class]}"
            end
          end
          numerate_highlighted_snippets if @hl_opts[:numerate]
          to_html
        end

        def highlight_snippet_part(text)
          if @hl_opts[:snippet_part_wrapper].blank?
            raise ArgumentError.new('Snippet part wrapper tag is not specified!')
          end
          wrapper = create_element("#{@hl_opts[:snippet_part_wrapper]}", class: "#{@hl_opts[:snippet_part_wrapper_class]}")
          wrapper.content = text
          wrapper
        end

        private

        def highlighting_default_options(options)
          @hl_opts = {
              base_selector: 'body',
              base_content_wrapper: '',
              base_content_wrapper_class: 'highlighting-base',
              snippet_container_class: 'highlighted-snippet',
              snippet_part_wrapper: 'span',
              snippet_part_wrapper_class: 'highlighted-snippet-part',
              numerate: true,
              numeration_attr: 'data-snippet-id',
              numeration_prefix: '',
              numeration_suffix: '',
          }.merge(options)
        end

        def highlighting_base
          base = at(@hl_opts[:base_selector])
          raise ArgumentError.new('Document does not contain highlighting base element!') if base.blank?
          if @hl_opts[:base_content_wrapper].present?
            wrapper = create_element("#{@hl_opts[:base_content_wrapper]}", class: "#{@hl_opts[:base_content_wrapper_class]}")
            base.children.each{|child| child.parent = wrapper}
            wrapper.parent = base
            return wrapper
          end
          base
        end

        def numerate_highlighted_snippets
          css(".#{@hl_opts[:snippet_container_class]}").each_with_index do |snippet_container, index|
            snippet_container[@hl_opts[:numeration_attr]] =
                "#{@hl_opts[:numeration_prefix]}#{index}#{@hl_opts[:numeration_prefix]}"
          end
        end

      end
    end
  end
end