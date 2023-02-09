#!/usr/bin/env ruby
# frozen_string_literal: true

require "phlex"
require "haml"
require "hamlit"
require "slim"
require "benchmark/ips"

require_relative "../fixtures/page"
require_relative "../fixtures/layout"

# Sample Data
Product = Struct.new(:name, :price, :color)
@products = [
	Product.new("Product 1", 10, "red"),
	Product.new("Product 2", 20, "green"),
	Product.new("Product 3", 30, "blue"),
	Product.new("Product 4", 40, "yellow"),
	Product.new("Product 5", 50, "orange")
]

# Templates
@fixtures_path = File.expand_path("../fixtures", __dir__)
@haml_layout = Haml::Template.new(File.join(@fixtures_path, "haml", "layout.haml"), escape_html: false)
@haml_page = Haml::Template.new(File.join(@fixtures_path, "haml", "page.haml"), escape_html: false)

@hamlit_layout = Hamlit::Template.new(File.join(@fixtures_path, "haml", "layout.haml"), escape_html: false)
@hamlit_page = Hamlit::Template.new(File.join(@fixtures_path, "haml", "page.haml"), escape_html: false)

@slim_layout = Slim::Template.new(File.join(@fixtures_path, "slim", "layout.slim"))
@slim_page = Slim::Template.new(File.join(@fixtures_path, "slim", "page.slim"))

@phlex_page = Example::Page.new(products: @products)

# Helper methods
def html_from_slim
	@slim_layout.render do
		@slim_page.render(Object.new, products: @products)
	end
end

def html_from_haml
	@haml_layout.render do
		@haml_page.render(Object.new, products: @products)
	end
end

def html_from_hamlit
	@hamlit_layout.render do
		@haml_page.render(Object.new, products: @products)
	end
end

def html_from_phlex
	@phlex_page.call
end

def check_html_is_same(a, b)
	raise "HTML is not the same" unless a == b
end

# Not sure why we need to compare, but moved this to a separate method?
check_html_is_same(html_from_phlex, html_from_phlex)

# HAML & Phlex produce the same HTML but HAML is using ' and Phlex is using ", also HAML is using \n, and Phlex producing a really long line :)
# The only other difference is order of attributes, but that's not important
# HAML: <meta content='width=device-width,initial-scale=1' name='viewport'>
# Phlex: <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
# check_html_is_same(html_from_phlex, html_from_haml(@haml_layout, @haml_page).gsub("\n", "").gsub("'","\""))

Benchmark.ips do |x|
	puts RUBY_DESCRIPTION
	x.config(time: 5, warmup: 2)
	x.report("Phlex Page") { html_from_phlex }
	x.report("HAML Page") { html_from_haml }
	x.report("Hamlit Page") { html_from_hamlit }
	x.report("Slim Page") { html_from_slim }
	x.compare!
end