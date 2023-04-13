(Tested only on Linux)

This is a directory/file listing tool.

Similar to what ls and tree do, except it doesn't have all of their features. 

It has different modes to list the contents of a directory. 

### Normal View
This is how it normally looks.

![](https://i.imgur.com/svq0FJk.jpg)

### List Mode
Show items in a vertical list.

![](http://i.imgur.com/VYrZRy9.jpg)

## Tree Mode

`--tree` or `-t`

This shows directory content in a tree view:

![](http://i.imgur.com/NS2VS6t.jpg)

## Snippets Mode

`--snippets` or `-s`

Show previews of text files.

![](http://i.imgur.com/pTx44Er.jpg)

It works in tree mode too.

![](http://i.imgur.com/YuQfs2A.jpg)

`--snippets-length` or `-n` can be used to control the snippet size.

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