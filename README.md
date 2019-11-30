(Tested only on Linux)

This is a simple directory/file listing tool.

Similar to what ls does, except it doesn't have all of its features.

### Normal view with --count
This is how it normally looks.

Here it's using a flag to count the items inside each directory.

![](http://i.imgur.com/4nqtgSp.jpg)

### Salad Mode
This is a preset that turns on certain options to make it look like this.

It enables --fluid, meaning files, directories, are not in their own block.

Also removes titles with --no-titles.

![](http://i.imgur.com/I9xXxrg.jpg)

### Blender Mode
This is a preset that turns on certain options to make it look like this.

It enables --fluid, --mix, and --no-titles.

--mix means sort everything in a single list, disregarding type.

![](http://i.imgur.com/CTlYLxe.jpg)

### List Mode
Show items in a vertical list.

![](http://i.imgur.com/gDbc3ag.jpg)

## Using --abc
Categorize results by letters.

![](http://i.imgur.com/7m9adHl.jpg)

## Filtering with regex
You can use regex to filter results.

Just add re: to the filter.

Of course you can just use a non regex string to do so.

![](http://i.imgur.com/1qxwL1f.jpg)

## Extra information
Here's using the --prefix and --size flags.

These show on the left if it's a D (Directory) or F (File).

It also shows the size on the right of files.

![](http://i.imgur.com/vTrHHFY.jpg)

Here's using the -P (or --permissions) flag:

![](http://i.imgur.com/u0tkzQL.jpg)

Here's using the -h (--header) flag:

![](http://i.imgur.com/sVWSOmp.jpg)

Also calculate directory size with -D or --dsize:

![](http://i.imgur.com/dFypcFX.jpg)

## Tree View

This shows directory content in a tree view:

Some special labels are "Excluded" and "Empty".

![](http://i.imgur.com/sXBFc4R.jpg)

## Sorting

Sorting is also possible. Either by size or modification date.

`--sizesort (-i)` for sorting by size (biggest files first)

`--datesort (-d)` for sorting by date (recently modified first)

## Exclude

Excluding files affects modes like --tree

It can be specified multiple times.

i.e myprogram --exclude=bigDir -e=.git -e=target
 
It is checked as:

```
full_path.contains(&"/{e}/")
```

So if ".git" is excluded then

it will match whatever contains `/.git/` for instance,

and not show its content in the tree view.

## Config File

In Linux a config is placed in ~/config/lq/lq.conf

It uses the TOML format.

Right now it has a section to add directories to exclude.

It looks like this:

```
exclude = [
  ".git",
  ".svn",
  "node_modules"
]
```

## Color Theme
It's possible to override the default colors using the config file.

Settings look like:
```
# Available colors:
# black, red, green, yellow, blue,
# magenta, cyan, white
[colors]
# Dir items
dirs = "cyan"
# Dir Link items
dirlinks = "blue"
```

![](http://i.imgur.com/B8Pc458.jpg)

### [All available flags](https://madprops.github.io/lq/)