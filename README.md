# pbdevflow - a custom zsh theme

**pbdevflow** is a minimalist yet informative custom theme for Oh My Zsh, perfect for developers.

The theme is designed and optimized for [Nerd Fonts](https://www.nerdfonts.com/) (recommended font is **Fira Code Nerd Font**), which allows you to use icons to conveniently display repository status and other elements.

![pbdevflow screenshot](./images/pic_1.png)

## Key Features
- **Path** - shows the current path.
- **Username** - shows the current user.
- **Git Integration** — shows the active branch and repository status:
- 🟠 **Changed** ( + number of modified files)
- ⚫ **Clean repository**
- **Icons** — uses Nerd Fonts to display information.

## Installation

1. Clone the repository
```sh
git clone https://github.com/pbarovsky/pbdevflow.git
```
2. Put the .zsg-theme file in the ~/.oh-my-zsh/custom/themes folder

3. Open the `~/.zshrc` file and change the theme
```sh
ZSH_THEME="pbdevflow"
```

4. Apply changes
```
source ~/.zshrc
```

## License
pbdevflow is distributed under the **MIT** license.