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

![](http://i.imgur.com/TjFkbkN.jpg)

## Sorting

Sorting is also possible. Either by size or modification date.

`--sizesort (-i)` for sorting by size (biggest files first)
`--datesort (-d)` for sorting by date (recently modified first)

### [All available flags](https://madprops.github.io/lq/)