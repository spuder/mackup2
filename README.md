## Mackup2

Fork of the [Ira/Mackup](https://github.com/lra/mackup/blob/master/mackup/applications/git.cfg) application written entirely in bash.

### Why this exists

OSX Sonoma changed how sandboxing works, so most applications [can no longer follow symlinks](https://github.com/lra/mackup/issues/1924#issuecomment-2026186178) 😢


mackup2 is a bash script that is largely compatible with the extensive library of [mackup `.cfg` files](https://github.com/lra/mackup/tree/master/mackup/applications)

The magic behind `mackup` was creating symlinks between `~/Libarary/Application Support/foo` directory and icloud/Dropbox/Google Drive. 

`mackup2` replicates this behavior by syncing folder/files to iCloud/Dropbox/Google Drive instead of symlinking. 
`mackup2` should be completely invisble to sandboxed applications.

⚠️ This code is `beta`, proceede with caution!


## Preflight

Before using `mackup2`, you must competely remove all symlinks that `mackup` created. 
If you still have mackup installed, the simplest solution is to run the following: 

```bash
mackup uninstall
```

## Setup

Since mackup2 is written in bash, it requires 2 libraries. They can easily be installed with [homebrew](https://brew.sh)

```bash
brew install unison
brew install autozimu/homebrew-formulas/unison-fsmonitor
```

## Usage

1. Manually copy the application config files you wish to sync to `~/.mackup2/`

    e.g. 
    ````bash
    mkdir ~/.mackup2
    cp ~/.mackup/git.cfg ~/.mackup2/git.cfg
    ```

2. Install mackup2

    ```bash
    make install
    ``` 

3. Start mackup2

    ```bash
    /usr/local/bin/mackup2-watchdog
    ```

4. Report back your success/failures

If you have an application that works, please open a pull request to add it to [mackup2/applications](mackup2/applications/)

## Logging

Logs are stored in `~/Library/Logs/mackup2`

## How it works

This script is designed to be as compatible with mackup config files as possible. For the most part you can migrate `~/.mackup/*` to `~/.mackup2/`.  

For every file listed under `[configuration_files]`, mackup2 will create a syncronization job for each file and folder using [unison](https://github.com/bcpierce00/unison)

1. It reads `~/.mackup/*.cfg` files
2. For each config file, read the app name and `[configuration_files]` section
3. For each file under `[configuration_files]` this script starts a new `unison -watch` process


### Bullsh*t, what does it really do to my files

👀 Here is a simple example to emulate what `mackup2` is doing under the hood

Create 2 directories:
```
mkdir /tmp/foo
mkdir /tmp/bar
```

Manually start unison to watch the 2 directories
```
unison -auto -batch -repeat watch /tmp/foo /tmp/bar
```

Unison creates a 2 way syncronization between the folders. Any file added to one, will be instantly copied to the other

```
touch /tmp/foo/file1.txt
ls /tmp/bar # <- observe that file1.txt has been magically copied to /tmp/bar
```

cleanup
```
pkill unison
rm -r /tmp/foo
rm -r /tmp/bar
```


## Design

The main magic of `mackup2` is this line of code

```bash
nohup unison -auto -batch -repeat watch -terse -prefer "$destination_path" "$source_path" "$destination_path" | tee -a "$HOME/Library/Logs/mackup2/$app_name.log" &
```

Note the flat `-prefer "$destination_path"`. 
This means that if a conflict happens between icloud and local, `unision` will prefer the icloud version.
This will ensure that a new computer won't clobber the configs of exiting devices. 


## Limitations

Because the syncing process requires a daemon to be constantly running, you must restart `mackup2` on _all_ machines when modifying a config file. 

Eventually `mackup2` will be 100% compatible with `mackup`. See current compatiblity chart below.

🚧 Features are still in progress. 🚧

Currently supported features: ()

### OS

- ✅ OSX
- ❌ Linux

### Clouds

- ✅ iCloud
- ❌ Dropbox
- ❌ Google Drive
- ❌ File

### Configurations

- ✅ `[application]`
- ✅ `[configuration_files]`
- ❌ `path`
- ❌ `directory`
- ❌ `storage`
- ❌ `[applications_to_sync]`
- ❌ `[applications_to_ignore]`
- ❌ `[xdg_configuration_files]`

### Misc

- ⚠️ Assumes all files are relative to `~/.`
- ❌ Prompt user before overwriting files
- ❌ Automated restarting of daemon

## Development

Pull Requests Welcome! 

## Troubleshooting


A file/folder isn't synchronizing

Look for a hidden `.unison..foobar.tmp` file in the same directory as the source file, then delete it. 