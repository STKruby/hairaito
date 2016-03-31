# Hairaito

Extends Nokogiri with text snippets highlighting. It looks like jquery-highlight plugin, but for ruby and nokogiri.

## Installation

Add this line to your application's Gemfile:

    gem 'hairaito'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hairaito

## Usage

Hairaito adds to Nokogiri::XML::Document _highlight_ method.

Example:

```
doc = Nokogiri::XML('<body>abc def ghi</body>')
doc.highlight(['def'])
doc.to_html # => '<body>abc <span class="snippet-part snippet-start" data-snippet-id="0">def</span> ghi</body>'
```

There are several options for highlighting customization:

```
{
  highlight_base: {
      selector: 'body',                             # Highlighting will be launched at this selector
      content_wrapper: '',                          # Highlighting base content can be wrapped by this tag
      content_wrapper_class: 'highlighting-base',   # Class for wrapper above
  },
  snippet: {
      part_wrapper: 'span',                         # Found snippet parts will be wrapped with this tag
      part_wrapper_class: 'snippet-part',           # Class for wrapper above
      starting_part_class: 'snippet-start',         # Class for wrapper above, is added only for first part per found snippet
  },
  numeration: {
      attr: 'data-snippet-id',                      # Snippet parts of single snippet will have same numeration value in this attribute
      prefix: '',                                   # Prefix, that will be added to each numeration value
      suffix: '',                                   # Suffix, that will be added to each numeration value
      start_with: 0,                                # Starting point for numeration increment
  },
  boundaries: {
    whole_words_only: true,                         # If true, only whole words will be found
    inline_tags: %w(a b i s u basefont big em font img label small span strike strong sub sup tt), # Tags, that aren't considered as word boundary
    word_parts: '[а-яА-ЯёЁa-zA-Z\d]',               # Characters, that are considered as word part
  },
}
```

Example:

```
doc = Nokogiri::XML('<body>abc def ghi abcdefghi</body>')
options = {
    highlight_base: {
      content_wrapper: 'div',
    },
    snippet: {
      starting_part_class: 'start',
      part_wrapper_class: 'part',
    },
    numeration: {
      attr: 'data-id',
      prefix: 'snippet_'
    },
    boundaries: {
      whole_words_only: false,
    }
}
doc.highlight(['abc'], options)
doc.to_html # => '<body><div class="highlighting-base"><span class="part start" data-id="snippet_0">abc</span> def ghi <span class="part start" data-id="snippet_1">abc</span>defghi</div></body>'
```

## Contributing

1. Fork it ( https://github.com/dmazilov/hairaito/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
