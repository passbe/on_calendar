# OnCalendar

Provides a library to parse [Systemd.Time calendar expressions](https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events) and determine future iterations. 

## Getting started

Add OnCalendar to your project:

```bash
gem install on_calendar
```
```ruby
require "on_calendar"
```
Or using bundler:

```bash
bundle add on_calendar
```

Parse your expression, should your expression be invalid a `OnCalendar::Parser::Error` will be raised:

```ruby
OnCalendar::Parser.new("Mon,Wed,Fri 10:23")
=> #<OnCalendar::Parser:0x00007f4725b55978

OnCalendar::Parser.new("00")
=> # Exception: OnCalendar::Parser::Error
```

Determine the next future iteration of this expression:

```ruby
OnCalendar::Parser.new("Mon,Wed,Fri 10:23").next
=> [2025-09-01 10:23:00.000000000 AEST +10:00]
```

If you need to find multiple iterations, supply a count argument:

```ruby
OnCalendar::Parser.new("Mon,Wed,Fri 10:23").next(10)
=>
[2025-09-01 10:23:00.000000000 AEST +10:00,
 2025-09-03 10:23:00.000000000 AEST +10:00,
 2025-09-05 10:23:00.000000000 AEST +10:00,
 2025-09-08 10:23:00.000000000 AEST +10:00,
 2025-09-10 10:23:00.000000000 AEST +10:00,
 2025-09-12 10:23:00.000000000 AEST +10:00,
 2025-09-15 10:23:00.000000000 AEST +10:00,
 2025-09-17 10:23:00.000000000 AEST +10:00,
 2025-09-19 10:23:00.000000000 AEST +10:00,
 2025-09-22 10:23:00.000000000 AEST +10:00]
```

By default `next` will use the current time and zone, but you can time travel using the `clamp` argument to pin the starting time:

```ruby
OnCalendar::Parser.new("Mon,Wed,Fri 10:23").next(10, clamp: Time.now - 20.years)
=>
[2005-08-31 10:23:00.000000000 AEST +10:00,
 2005-09-02 10:23:00.000000000 AEST +10:00,
 2005-09-05 10:23:00.000000000 AEST +10:00,
 2005-09-07 10:23:00.000000000 AEST +10:00,
 2005-09-09 10:23:00.000000000 AEST +10:00,
 2005-09-12 10:23:00.000000000 AEST +10:00,
 2005-09-14 10:23:00.000000000 AEST +10:00,
 2005-09-16 10:23:00.000000000 AEST +10:00,
 2005-09-19 10:23:00.000000000 AEST +10:00,
 2005-09-21 10:23:00.000000000 AEST +10:00]
```

Timezones are supported in expressions and the `clamp` argument. However all calculated iterations will default to the timezone set in the expression. The local timezone will be used if nothing is specified.

## Limitations

A few limitations do exist at this stage:

* No support for the `~` operator.
* Time can only be specified to seconds and not sub-second level.
* Timezones must be specified as IANA TZ identifiers (ie: Australia/Brisbane, not +1000)
* Determining past iterations of an expression.

## Support

Should you find a bug or have ideas, feel free to open an issue and I'll do my best to get back to you.

## License

This gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Contribution guide

Pull requests are welcome! Please make sure you include tests for any changes.
