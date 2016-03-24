require 'nokogiri'
require 'hairaito/version'

module Hairaito
end

directory = Pathname.new(File.dirname(__FILE__))
Dir.glob(directory.join('hairaito', '*.rb')) { |file| require file }
Dir.glob(directory.join('hairaito', '**/*.rb')) { |file| require file }

Nokogiri::XML::Document.send(:include, Hairaito::Nokogiri::XML::Document)
Nokogiri::XML::Node.send(:include, Hairaito::Nokogiri::XML::Node)

