# mite-backup

Simple command-line tool for downloading a backup in XML of your [mite](http://mite.yo.lk/en).account.

## Installation

    gem install mite-backup
    
## Usage

    mite-backup -a [ACCOUNT] -e [EMAIL] -p [PASSWORD]
    
This will output the backup file in XML to the prompt. You propably want to pipe it into an file:

    mite-backup -a [ACCOUNT] -e [EMAIL] -p [PASSWORD] > my_backup_file.xml

For further instructions run

    mite-backup -h
    

## BlaBla

Copyright (c) 2011 [Yolk](http://yo.lk/) Sebastian Munz & Julia Soergel GbR

Beyond that, the implementation is licensed under the MIT License.