# dotfiles

My personal dotfiles

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
