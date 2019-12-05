(Tested only on Linux)

This is a simple directory/file listing tool.

Similar to what ls does, except it doesn't have all of its features. 

It has different modes to list the contents of a directory. 

Most item styles are customizable, you can set for instance that directories should be "bright red" in the config file.

[Click here to see all available flags](https://madprops.github.io/lq/)

### Normal View
This is how it normally looks.

Items are separated in Directories, Files, and Executables.

Symlinks have different colors.

![](http://i.imgur.com/LzX5jD1.jpg)

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

![](http://i.imgur.com/YYMBaTj.jpg)

## ABC Mode
Categorize results by letters.

![](http://i.imgur.com/qllXg4d.jpg)

## Filtering with regex
You can use regex to filter results.

Just add re: to the filter.

Of course you can just use a non regex string to do so.

![](http://i.imgur.com/G1I9R25.jpg)

## Extra information
Here's using:

`--prefix`

`--dsize`

`--size`

`--sizesort`

![](http://i.imgur.com/ACrKVxd.jpg)

Here's using the -P (or --permissions) flag:

![](http://i.imgur.com/u0tkzQL.jpg)

Here's using the -h (--header) flag:

![](http://i.imgur.com/4izEKRH.jpg)

## Tree View

`--tree` or `-t`

This shows directory content in a tree view:

![](http://i.imgur.com/NS2VS6t.jpg)

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

## Color Theme
It's possible to override the default colors using the config file.

![](http://i.imgur.com/z42bWjI.jpg)