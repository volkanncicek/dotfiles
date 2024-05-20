# Volkan Cicek's Dotfiles

This repository contains my personal dotfiles and scripts for setting up my development environment.

## PowerShell setup (Windows)

- [Oh My Posh](https://ohmyposh.dev/) - Prompt theme engine
- [Terminal Icons](https://github.com/devblackops/Terminal-Icons) - Folder and file icons
- [PSReadLine](https://docs.microsoft.com/en-us/powershell/module/psreadline/) - Cmdlets for customizing the editing environment, used for autocompletion

## Git Multiple User Setup

Create a `.gitconfig` file in the home directory with the following content:

```bash
[includeIf "gitdir:~/personal/"]
    path = .gitconfig-personal
[includeIf "gitdir:~/work/"]
    path = .gitconfig-work
```

or

```bash
[includeIf "hasconfig:remote.*.url:git@github.com*/**"]
    path = .gitconfig-personal
[includeIf "hasconfig:remote.*.url:git@my.enterprise.local*/**"]
    path = .gitconfig-work
```

And create the corresponding `.gitconfig-personal` and `.gitconfig-work` files in the home directory with the following content:

```bash
[user]
    name = Your Name
    email = Your Email
```

# Programs

List of programs that I use on my personal computer:

- A desktop application for viewing and analyzing tabular data [Tad](https://github.com/antonycourtney/tad)
- Control display brightness & volume on Mac: [Monitor Control](https://github.com/MonitorControl/MonitorControl)
- Mac system monitor in menu bar: [Stats](https://github.com/exelban/stats)
- A desktop application for downloading Udemy Courses [Udeler](https://github.com/heliomarpm/udemy-downloader-gui)
- [Awesome Mac](https://github.com/jaywcjlove/awesome-mac)
- [Config (macOS / iOS)](https://github.com/nikitavoloboev/config)
- [Awesome Linux Software](https://github.com/luong-komorebi/Awesome-Linux-Software)
