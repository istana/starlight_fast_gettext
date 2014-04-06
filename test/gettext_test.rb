require_relative 'test_helper'

describe Starlight::FastGettext do

  before do
    @translator = Starlight::FastGettext.new(search_path: 'test/data/app', locales: ['en', 'sk'],
      locales_dir: 'test/data/locales', template_path: 'test/data/locales/template.yml')
  end
  
  it '#load_translations' do
    assert_equal({
      "en" => {
        "Welcome traveller" => nil,
        "Top" => nil,
        "Back" => nil
      },
      "sk" => {
        "Welcome traveller" => 'Vitaj, cestovateľ',
        "Top" => "Dohora",
        "Back" => "Späť",
        "Unused" => "Nepoužívaný"
      }
    }, @translator.load_translations)
  end

  it '#find_untranslated' do
    assert_equal({
      "en" => ["Welcome traveller", "Top", "Back"],
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
    assert_equal({
      "en" => {
        "Welcome traveller" => nil,
        "Top" => nil,
        "Back" => nil,
        "Missing One" => nil
      },
      "sk" => {
        "Welcome traveller" => 'Vitaj, cestovateľ',
        "Top" => "Dohora",
        "Back" => "Späť",
        "Unused" => "Nepoužívaný",
        "Missing One" => nil
      }
    }, @translator.fill_missing)
  end
  
  it '#remove_unused' do
    assert_equal({
      "en" => {
        "Welcome traveller" => nil,
        "Top" => nil,
        "Back" => nil,
      },
      "sk" => {
        "Welcome traveller" => 'Vitaj, cestovateľ',
        "Top" => "Dohora",
        "Back" => "Späť",
      }
    }, @translator.remove_unused)
  end
  
  it '#extract_translations' do
    assert_equal({
      "test/data/app/welcome.html.slim" => nil,
      "Welcome traveller" => nil,
      "Top" => nil,
      "Back" => nil,
      "Foo" => nil,
      "test/data/app/foo.html.erb" => nil,
      "Only in ERb" => nil
    }, @translator.extract_translations)
  end
  
  it '#export_xlsx' do
    file = File.join(@translator.locales_dir, "translations.xlsx")
    assert_equal true, @translator.export_xlsx(true, true, true, file)
    assert_equal(true, File.exists?(file))
    
    trans = Roo::Excelx.new(file)
    assert_equal [
      ["_Key", "_Translation"],
      ["Welcome traveller", "Vitaj, cestovateľ"],
      ["Top", "Dohora"],
      ["Back", "Späť"],
      ["Missing One", nil],
      ["Unused", "Nepoužívaný"]
    ], trans.sheet("sk").map{|row| row}
    assert_equal [
      ["_Key", "_Translation"],
      ["Welcome traveller", nil],
      ["Top", nil],
      ["Back", nil],
      ["Missing One", nil]
    ], trans.sheet("en").map{|row| row}
    
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
