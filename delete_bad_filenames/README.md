# deletes files with filenames that aren't ascii

## Features
- Interactive (asks for each before deleting)
- I've exhausted the my list of features

## Why did I need this?

It is quite often that I accidentally create a file or two with null characters in the filename, which can't be typed and tools like `ls` stop reading the filename at the null character, so I can't just copy and paste it either.

<sub>please don't ask why I keep accidentally creating files with null characters in the filename because I have no idea either</sub>
