## Description

These are script for downloading and converting videos from a [Tivo DVR](http://www.tivo.com/) using the TivoToGo API.
They are meant to be run regularly from cron to download and convert new videos.

# tivo_fetch

Fetches list of TV shows from Tivo (specified with --host option) and downloads all new files.
Must be passed the MAK from Tivo (--mak) for authorization and decryption.
Can decrypt (--decode) or convert to mp4 (--mp4).
Can name files based on [Plex TV Show naming guide](https://support.plex.tv/hc/en-us/articles/200220687-Naming-Series-Season-Based-TV-Shows) with --show option.
Can skip existing files (--skip).
Can use YAML file to map series names to the thetvdb.com names (--series-map )

  tivo_fetch --decode --show --skip --series-map=series.yml

# tivo_convert

Finds all .mpg files in current tree and converts them .m4v files.

# move_season

Moves file for TV episode to directory and file name based on 
Files are organized like "Show_Name/Season XX/ShowName - sXXeYY - Episode_name.ext".
For example,

  move_season "Futurama - Fry and Leela's Big Fling.mpg" 7 13
  
Moves file to "Futurama/Season 07/Futurama - s07e13 - Fry and Leela's Big Fling.mpg"

## Requires

[tivodecode](http://tivodecode.sourceforge.net/)
[ffmpeg](https://www.ffmpeg.org/)
[votigoto](http://votigoto.rubyforge.org/) gem. Requires forked version from https://github.com/ianburrell/votigoto.

## License

Copyright 2015 Ian Burrell

Released under the MIT license
