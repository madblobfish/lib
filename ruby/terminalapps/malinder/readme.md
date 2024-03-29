# malinder

`malinder` is a tool for working with a certain database.

## How it Works
After setting up the directories with sources, `malinder` loads this data into RAM. You can then execute various commands to create and manage a database (which we call log or logfile) that lists things you've seen or want to see.

* The `<year> <season>` command allows you to discover series of a season.
* The `results` command compares two such databases and finds common entries.
* The `malinder-db-pfusch.rb` script enables merging multiple databases (it is recommended to track a separate file for each group of people).
* Run `malinder` without arguments to learn the other commands.

Note: images displayed by `malinder` will be stored in `~/.cache/malinder/images`.

## Requirements
* For many operations, `malinder` does not require additional packages to be installed.
* The `query` command requires the `ruby/stdlib/array/query.rb` file in the correct relative location.
* The `<year> <season>` command requires the following:
	* The `ruby/games/lib/gamelib.rb` file in the correct relative location.
	* A terminal that supports the kitty graphics protocol.
	* The `libvips` library and `ruby-visp` gem.
	* Optional: the `ruby/stdlib/duration.rb` file in the correct relative location.
* A directory of JSON files downloaded from MyAnimeListAPI should be located in `~/.config/malinder/sources`.

## Configuration
An optional configuration file for `malinder` can be placed in `~/.config/malinder/config.rb`. The program respects the `HOME` and the `XDG_CACHE_HOME` environment variables according to the XDG Base Directory Specification.

Please refer to the `configurable_default` function within the code for customizable options such as:
```
DEFAULT_HEADERS = {'X-MAL-CLIENT-ID': 'asdf'}
LOG_SUFFIX = '-yourname'
```
To share or distribute `malinder` logs, it is recommended to set up your sources directory or the entire config directory as a git repository.

## Quickstart
```bash
gem install ffi ruby-vips
pacman -Syu libvips # or your distribution's way

git clone https://github.com/madblobfish/lib ~/madblobfish-lib
alias malinder="ruby ~/madblobfish-lib/ruby/games/malinder.rb"
mkdir ~/.config/malinder/; cd ~/.config/malinder
#echo LOG_SUFFIX = "-$USER" > config.rb # thats the default
git init; git add .; git commit -m 'init'
git clone git@server:malindersources sources # do this yourself lol
malinder --help
malinder search Black Jack | grep -P "\t-\t" | sed 's/\t-\t/\tnope\t/' >> ~/.config/malinder/choices-my.log
sed -re 's/\tnope\t/\tokay\t' ~/.config/malinder/choices-my.log > ~/.config/malinder/choices-relative.log
malinder 2000 winter
malinder stats
ruby ~/madblobfish-lib/ruby/games/malinder-db-pfusch.rb choices-relative.txt ~/.config/malinder/sharedfile.txt > /tmp/choices-my.log
cp /tmp/choices-my.log ~/.config/malinder/choices-$USER.log
malinder results choices-relative.log
```
