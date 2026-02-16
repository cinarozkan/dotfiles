# cinarozkan Dotfiles 🧑🏻‍💻⚙️🎨

All of my config files for my Arch Linux setup with KDE Plasma. This repository includes config files for:
- conky
- git
- konsole
- neofetch
- nvim
- powerlevel10k
- rofi
- wallpapers
- zsh

Clone the repository to `~/dotfiles` and run the `install-dotfiles.sh` script to automatically install all the dotfiles using GNU Stow.
```bash
git clone https://github.com/cinarozkan/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install-dotfiles.sh
```


## Getting my KDE Plasma Desktop

To get my KDE Plasma rice, first install **[konsave](https://github.com/Prayag2/konsave)** (I also suggest checking out **[KonUI](https://github.com/TheUruz/KonUI)**) from AUR or with pip, then import the latest `.knsv` file from the **releases** of this repository as a profile.
```bash
konsave -i plasma-v1.0.0.knsv
```

Apply the newly created profile.  
```bash
konsave -a plasma-v1.0.0.knsv
```

Some changes may not apply immediately; you may need to log out and log back in.  
After that, set your wallpapers manually from the `wallpapers` directory.


## Notes

- Some config files may need additional steps after being installed for them to actually work (for example, rofi and conky).  
- This repository does not automatically install the `pacman.conf`, If you want to use it, copy it to `/etc/pacman.conf`. You may also need to set up some extra repositories like chaotic-aur manually if you wish to use them.
- This repository is designed with Arch Linux in mind, but most things should work on other Linux distributions (and MacOS) too.

