# Dots

This repo contains all of my dotfiles that I'd like to track.

## Using my dots

To use these dotfiles, run the below script in order:

```bash
# Setup bare repo
alias config='/usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# Ensure bare repo is gitignored
echo ".dots" >> .gitignore

# Clone my dots into your bare repo
git clone --bare git@github.com:AWash227/dots.git $HOME/.dots

# Setup the 'dots' alias for use instead of 'git'
alias dots='/mkdir -p .config-backup && \

# Backup existing dots and use my dots instead
dots checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .dots-backup/{}usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# Prevent untracked files from being shown for your bare repo
dots config --local status.showUntrackedFiles no

```

## How does it work?

A git bare repo is used to track and manage changes to dotfiles.
For further information on how this works, please check out these links:

- [Ask HN: What do you use to manage dotfiles?](https://news.ycombinator.com/item?id=11070797)
- [Dotfiles: Best Way to Store in a Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)
- [The best way to store your dotfiles: A bare Git repository **EXPLAINED** ](https://www.ackama.com/what-we-think/the-best-way-to-store-your-dotfiles-a-bare-git-repository-explained/)

### Setup From Scratch

```bash
git init --bar $HOME/.dots
alias dots='/usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'
dots config --local status.showUntrackedFiles no
```
