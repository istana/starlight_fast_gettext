# StarlightFastGettext

Simple gem for managing FastGettext translations. It is able to extract translations
from source code, show untranslated, missing and unused translations and import and export from/to Excel spreadsheet.

## What works

- finding *_()* and *D_()* strings
- and stuff mentioned in description
- it is really cool

## Roadmap

- add support for n_() and d_() functions and pluralization
- perhaps add rake tasks

## Installation

Add this line to your application's Gemfile:

    gem 'starlight_fast_gettext'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install starlight_fast_gettext

## Credit

My inspiration was [i18n-tasks](https://github.com/glebm/i18n-tasks) gem, which manages translations for I18n (Rails is using it). The reason I programmed this is I wanted something much simpler than [i18n-tasks](https://github.com/glebm/i18n-tasks) and I had desire to wrote something from scratch.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/starlight_fast_gettext/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
