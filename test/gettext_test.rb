require_relative 'test_helper'

describe StarlightFastGettext do

	before do
		@translator = StarlightFastGettext.new(search_path: 'test/data/app',
																					 locales: ['en', 'sk'],
																					 locales_dir: 'test/data/locales',
																					 template_path: 'test/data/locales/template.yml'
																					)

		def @translator.log(msg, level = "info")
			nil
		end

		@sk = {
			"sk" => {
				"test/data/app/welcome.html.slim" => '_file_',
				"Welcome traveller" => 'Vitaj, cestovateľ',
				"Top" => "Dohora",
				"Back" => "Späť",
				"Foo" => "Niečo",
				"Unused" => "Nepoužívaný",
				"test/data/app/foo.html.erb" => '_file_',
				"Only in foo.html.erb" => "Iba v foo.html.erb"
			}
		}

		@en = {
			"en" => {
				"test/data/app/welcome.html.slim" => '_file_',
				"Welcome traveller" => nil,
				"Top" => nil,
				"Back" => nil,
				"Foo" => nil,
				"test/data/app/foo.html.erb" => '_file_',
				"Only in foo.html.erb" => nil
			}
		}
	end

	it '#load_translations' do
		assert_equal({}.merge(@sk).merge(@en), @translator.load_translations)
	end

	it '#find_untranslated' do
		assert_equal({
			"en" => ["Welcome traveller", "Top", "Back", "Foo", "Only in foo.html.erb"],
			"sk" => []
		}, @translator.find_untranslated)
	end

	it '#find_missing' do
		assert_equal({
			"en" => ["Missing One"],
			"sk" => ["Missing One"]
		}, @translator.find_missing)
	end

	it '#find_unused' do
		assert_equal({
			"en" => [],
			"sk" => ["Unused"]
		}, @translator.find_unused)
	end

	it '#fill_missing' do
		trans = {}
		trans.merge!(@sk)
		trans.merge!(@en)
		trans["sk"]["Missing One"] = nil
		trans["en"]["Missing One"] = nil
		assert_equal(trans, @translator.fill_missing)
	end

	it '#remove_unused' do
		expected = {}.merge(@sk).merge(@en)
		expected["sk"].delete("Unused")
		assert_equal(expected, @translator.remove_unused)
	end

	it '#extract_translations' do
		assert_equal({
			"test/data/app/welcome.html.slim" => "_file_",
			"Welcome traveller" => nil,
			"Top" => nil,
			"Back" => nil,
			"Foo" => nil,
			"Missing One" => nil,
			"test/data/app/foo.html.erb" => "_file_",
			"Only in foo.html.erb" => nil
		}, @translator.extract_translations)
	end

	it '#export_xlsx' do
		file = File.join(@translator.locales_dir, "translations.xlsx")
		assert_equal true, @translator.export_xlsx(true, true, true, file)
		assert_equal(true, File.exists?(file))

		trans = Roo::Excelx.new(file)

		slovak = @sk["sk"].merge("Missing One" => nil)
		slovak["_Key"] = "_Translation"

		english = @en["en"].merge("Missing One" => nil)
		english["_Key"] = "_Translation"

		assert_equal(slovak, Hash[trans.sheet("sk").map{|row| row}])
		assert_equal(english, Hash[trans.sheet("en").map{|row| row}])

		File.unlink(file)
	end

	it '#import_xlsx' do
		@translator.locales_dir = 'test/locales_import/'
		@translator.import_xlsx
		sk = File.join(@translator.locales_dir, 'sk.yml')
		en = File.join(@translator.locales_dir, 'en.yml')
		assert_equal true, File.exists?(sk)
		assert_equal true, File.exists?(en)

		assert_equal({
			"sk" => {
				"Welcome traveller" => "Vitaj, cestovateľ",
				"Top" => "Dohora",
				"Back" => "Späť",
				"Missing One" => nil,
				"Unused" => 
				"Nepoužívaný"
			}
		}, YAML::load_file(sk))
		assert_equal({
			"en" => {
				"Welcome traveller" => nil,
				"Top" => nil,
				"Back" => nil,
				"Missing One" => nil
			}
		}, YAML::load_file(en))

		FileUtils.rm_rf @translator.locales_dir
	end
end
