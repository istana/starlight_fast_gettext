require_relative "./starlight_fast_gettext/version.rb"

require 'active_support/core_ext/hash/deep_merge.rb'
require 'active_support/core_ext/object/deep_dup.rb'
require 'active_support/core_ext/object/blank.rb'
require 'yaml'
require 'axlsx'
require 'roo'
require 'fileutils'


# The program is for management of translations
# translations are stored in a YAML file as an hash
# template is "empty translation" and is created by extracting translations from files
# there are methods which returns the result and similar which writes the result to the file
#
class StarlightFastGettext
	attr_accessor :locales, :locales_dir, :template_path, :export_file, :import_file
	def initialize(options = {})
		if defined?(Rails)
			base = Rails.root
		else
			base = '.'
		end

		@search_path = File.join((options[:search_path] || File.join(base, 'app')), '**')
		@locales = options[:locales] || (FastGettext.locales rescue nil) || ['en']
		@locales_dir = options[:locales_dir] || File.join(base, 'config', 'locales')
		@template_path = options[:template_path] || File.join(@locales_dir, 'template.yml')
		@export_file = options[:export_file] || File.join(@locales_dir, 'translations_export.xlsx')
		@import_file = options[:import_file] || File.join(@locales_dir, 'translations_import.xlsx')

		@literal_re = /".+?"|'.+?'/
		@extract_rules = [ 
			{ 
				# _('Crate'), s_('Namespace|Crate'), D_('search all domains for Crate')
				id: 'one_arg',
				name: 'slim, erb and haml with one argument (translation)',
				regexp: /\b(s|D)?_[( ](#{@literal_re})/,
				files: '*.{slim,erb,haml,rb}'
			},
			#{
			#  name: 'slim, erb and haml with domain support TODO',
			#  regexp: /\b(dn|d|)?_[( ](#{@literal_re}, *#{@literal_re})/,
			#  files: '*.{slim,erb,haml}'
			#}
			# TODO: n_ takes more arguments
		]

	end

	def log(msg, level = 'info')
		puts "#{level.upcase}: #{msg}"
	end

	# load translations from files
	def load_translations
		for_locale do |template, translations, locale|
			translations
		end
	end

	# returns array of untranslated items from translations
	def find_untranslated(options = {})
		for_locale do |template, translations, locale|
			#translations.deep_merge(template).keep_if do |key, translation|
			#  translation.blank? ? true : false
			#end.keys
			translations.keep_if do |key, translation|
				translation.blank? ? true : false
			end.keys
		end
	end

	# return translations found in the template and not in translations file
	def find_missing(options = {})
		for_locale do |template, translations, locale|
			template.keys - translations.keys
		end
	end

	# returns translations found in the translations file and not in the template
	def find_unused(options = {})
		for_locale do |template, translations, locale|
			translations.keys - template.keys
		end
	end

	# adds translations from template to translations file
	def fill_missing(options = {})
		for_locale do |template, translations, locale|
			translations = template.deep_merge(translations)
		end
	end

	# removes translations from translations file which are not present in the template
	def remove_unused(options = {})
		unused = find_unused
		for_locale do |template, translations, locale|
			translations.keep_if do |k, v|
				!unused[locale].include?(k)
			end
		end
	end

	# this extracts translations and creates template - hash of translation keys with nil
	# translation values
	def extract_translations
		extracted = {}
		@extract_rules.each do |rule|
			path = File.join(@search_path, rule[:files])
			log "Searching for #{path}"
			Dir[path].each do |f|
				log "Processing #{f}"
				content = File.read(f)

				extracted[rule[:id]] ||= {}
				extracted[rule[:id]][f] ||= []
				# remove quotes from string
				extracted[rule[:id]][f] += content.scan(rule[:regexp]).map do |arr|
					[arr[0], arr[1][1..-2]]
				end
			end
		end

		# transforms translations extracted with one_arg rule into hash
		# and result is template
		extracted['one_arg'].reduce({}) do |result, (file, keys)|
			# add information about file, kind of metadata
			result[file] =  '_file_'
			# take only translation key
			# NOTE: duplicate keys in different files WILL BE deduplicated
			# also need Ruby 1.9.3+ to ordered hash (for file information)
			# key[0] is _ or s_ or D_
			keys.each {|key| result[key[1]] = nil }
			result
		end
	end

	def extract_and_write_translations
		write_template(extract_translations)
	end

	# exports translations into xlsx 
	def export_xlsx(extract = true, keep_unused = true, add_missing = true, file = @export_file)
		extract_translations if extract
		trans = load_translations
		trans = remove_unused(translations: trans) if !keep_unused
		trans = fill_missing(translations: trans) if add_missing

		p = Axlsx::Package.new
		wb = p.workbook

		for_locale(translations: trans) do |template, translations, locale|
			wb.add_worksheet(name: locale) do |sheet|
				# the header is for row always have two items (for import)
				sheet.add_row ['_Key', '_Translation']

				translations.each do |k, v|
					sheet.add_row [k, v]
				end
			end
		end
		p.serialize(file)
	end

	# replaces translations with these from excel file
	def import_xlsx(file = @import_file)
		s = Roo::Excelx.new(file)

		all = {}
		s.sheets.each do |locale|
			all[locale] ||= {}
			s.sheet(locale).each_with_index do |row, i|
				next if i == 0
				all[locale].deep_merge!(Hash[row[0], row[1]])
			end
		end 

		for_locale(translations: all, template: []) do |template, translations, locale|
			write_translations(locale, translations)
		end
		true
	end

	private

	def read_template
		YAML::load_file(@template_path)
	end

	def write_template(template)
		FileUtils.mkpath(File.dirname(@template_path))
		File.write(@template_path, YAML::dump(template))
	end

	def read_translations(loc)
		YAML::load_file(File.join(@locales_dir, "#{loc}.yml"))
	end

	def write_translations(loc, translations)
		FileUtils.mkpath @locales_dir
		File.write(File.join(@locales_dir, "#{loc}.yml"), YAML::dump(loc => translations))
	end

	# iterate function for a locale
	def for_locale(options = {}, &block)
		if options[:template].respond_to?(:[])
			template = options[:template]
		else
			template = read_template
		end

		@locales.reduce({}) do |result, locale|
			if options[:translations].respond_to?(:[])
				translations = options[:translations][locale]
			else
				translations = read_translations(locale)[locale]
			end
			result[locale] = block.call(template, translations, locale)
			result
		end
	end

end
