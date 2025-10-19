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
	* The `text-hyphen` gem, for nice hyphenation in the word breaking algorithm.
	* Optional: the `ruby/stdlib/duration.rb` file in the correct relative location.
	* Optional: the `ruby/stdlib/string/contains_japanese?.rb` file in the correct relative location.
* A directory of JSON files downloaded from MyAnimeListAPI should be located in `~/.config/malinder/sources`.

## Configuration
An optional configuration file for `malinder` can be placed in `~/.config/malinder/config.rb`. The program respects the `HOME` and the `XDG_CACHE_HOME` environment variables according to the XDG Base Directory Specification.

Please refer to the `configurable_default` function within the code for customizable options such as:
```
DEFAULT_HEADERS = {'X-MAL-CLIENT-ID': 'asdf'}
LOG_SUFFIX = '-yourname'

#configure how long to wait until again pulling automatically
# AUTOPULL_SOURCES_WAIT = 86400*2

#configure watch command adding subtitles from here and updating them regularly, assuming its a git
# SUBTITLES_PATH = '/some/folder/'
# AUTOPULL_SUBTITLES_WAIT = 3600
```
To share or distribute `malinder` logs, it is recommended to set up your sources directory or the entire config directory as a git repository.

### git automerge of choices-\*.log files

Write the following into your git-config, e.g. `.git/config`:
```ini
[merge "malinder"]
	name = malinder db-pfush
	driver = ruby /path/to/malinder/malinder-db-pfusch.rb --nocurrent --gitmerge --inplace %A %O %B
	recursive = text
```
And this into `.gitattributes`:
```
choices-*.log merge=malinder
```

Then merges will be automatically handled.

## Quickstart
```bash
# setup
gem install ffi ruby-vips text-hyphen
pacman -Syu libvips # or your distribution's way

git clone https://github.com/madblobfish/lib ~/madblobfish-lib
alias malinder="ruby ~/madblobfish-lib/ruby/games/malinder.rb"
mkdir ~/.config/malinder/; cd ~/.config/malinder
#echo LOG_SUFFIX = "-$USER" > config.rb # thats the default
git init; git add .; git commit -m 'init'
git clone git@server:malindersources sources # do this yourself lol, meaning you need to load the seasonal files from mal

# querying and filling up your own list
malinder --help
malinder search Black Jack | grep -P "\t-\t" | sed 's/\t-\t/\tnope\t/' >> ~/.config/malinder/choices-my.log
sed -re 's/\tnope\t/\tokay\t' ~/.config/malinder/choices-my.log > ~/.config/malinder/choices-relative.log
malinder 2000 winter
malinder log 1 seen; malinder log 1 4
malinder db-pfusch --inplace choices-relative.txt ~/.config/malinder/sharedfile.txt
malinder stats
malinder results choices-relative.log
malinder results name 2030 winter # will use the 'choices-name.log' file

# watch and file helpers, mostly interactive
malinder fix-names
malinder clean
malinder missing
malinder watch

# git integration
malinder add # runs git add -p
malinder commit --push # defaults to a iso date YYYY-MM-DD commit message
malinder pull/push/log # runs git commands as well # pulling is automatically done on a configurable regular basis
```
