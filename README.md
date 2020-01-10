(Tested only on Linux)

This is a directory/file listing tool.

Similar to what ls and tree do, except it doesn't have all of their features. 

It has different modes to list the contents of a directory. 

Most item styles are customizable, you can set for instance that directories should be "bright red" in the config file.

[Click here to see all available flags](https://madprops.github.io/lq/)

### Normal View
This is how it normally looks.

Items are separated in Directories, Files, and Executables.

Symlinks are underlined.

Executables are bold.

![](http://i.imgur.com/SpBLu0V.jpg)

### Fluid Mode 1

Show all items in a single block.

`--fluid` or `-u`

![](http://i.imgur.com/3STTzwp.jpg)

### Fluid Mode 2

Some fluidity with included titles.

`--fluid2` or `-U`

![](http://i.imgur.com/IGQUqg0.jpg)

### List Mode
Show items in a vertical list.

![](http://i.imgur.com/VYrZRy9.jpg)

## ABC Mode
Categorize results by letters.

![](http://i.imgur.com/svvsAoK.jpg)

## Tree Mode

`--tree` or `-t`

This shows directory content in a tree view:

![](http://i.imgur.com/NS2VS6t.jpg)

## Snippets Mode

`--snippets` or `-s`

Show previews of text files.

`--snippets-length` or `-n` can be used to control the snippet size.

![](http://i.imgur.com/tatP5m9.jpg)

![](http://i.imgur.com/cWhuZrp.jpg)

## Filtering with regex
You can use regex to filter results.

Just add re: to the filter.

Of course you can just use a non regex string to do so.

![](http://i.imgur.com/Vc1NdLg.jpg)

## Extra information
Here's using:

`--prefix` (-p) (Show a prefix like [D] or [F])

`--permissions` (-P) (Show item's permissions)

`--date` (-k) (Show the last time files were modified) 

`--dirdate` (-K) (Show the last time directories were modified)

`--size` (-z) (Show file size)

`--dirsize` (-Z) (Show dir size)

`--header` (-h) (Show some context above)

`--count` (-c) (Count items inside directories)

![](http://i.imgur.com/zteReJV.jpg)

There's a preset `--info` (-?) that enables all size and date flags.

## Sorting

Sorting is also possible. Either by size or modification date.

`--sizesort (-i)` for sorting by size (biggest files first)

`--datesort (-d)` for sorting by date (recently modified first)

## Config File

In Linux a config is placed in ~/config/lq/lq.conf

It uses the TOML format.

Right now it has sections to exclude paths

and to change the color theme.

It looks like this:

```
exclude = [
  ".git",
  ".svn",
  "node_modules"
]
```

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

## Color Theme
It's possible to override the default colors using the config file.

![](http://i.imgur.com/z42bWjI.jpg)