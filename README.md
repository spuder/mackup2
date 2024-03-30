## Mackup 2

Proof of concept recreation of the [Ira/Mackup](https://github.com/lra/mackup/blob/master/mackup/applications/git.cfg) application

### Why this exists

OSX Sonoma changed how sandboxing works, so most applications [can no longer follow symlinks](https://github.com/lra/mackup/issues/1924#issuecomment-2026186178) 😢

Solution is to copy files back and forth instead of symlinking

⚠️ This code is highly expirimental, use with extreem caution ⚠️


## Setup

```bash
brew install unison
brew install autozimu/homebrew-formulas/unison-fsmonitor
```

## Usage

1. Manually copy the applications you wish to sync to `~/.mackup2/`

2. Run mackup

    ```bash
    chmod +x mackup2.sh
    ./mackup2.sh
    ``` 

    To stop syncing, press `ctrl + c`

3. Report back your success/failures

If you have an application that works, please open a pull request to add it to [mackup2/applications](mackup2/applications/)


## Logging

Logs are sent with `logger`. To view logs, open `console` from the utilities directory and search for `mackup2`

## How it works

This script is designed to be as compatible with mackup config files as possible. For the most part you can migrate `~/.mackup/*` to `~/.mackup2/`.  

For every file listed under `[configuration_files]`, mackup2 will create a syncronization job for each file and folder using [unison](https://github.com/bcpierce00/unison)

1. It reads ~/.mackup/*.cfg files
2. For each config file, read the app name and `[configuration_files]` section
3. For each file under `[configuration_files]` this script starts a new `unison -watch` process


### Bullsh*t, what does it really do to my files

👀 Here is a simple example

Create 2 directories:
```
mkdir /tmp/foo
mkdir /tmp/bar
```

Manually start unison to watch the 2 directories
```
unison -auto -batch -repeat watch /tmp/foo /tmp/bar &
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


## Limitations

🚧 Features are still in progress. 🚧

Currently supported features: 

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


## Troubleshooting


A file/folder isn't syncronizing

Look for a hidden `.unison..foobar.tmp` file in the same directory as the source file, then delete it. 