
#!/usr/bin/env python3

from pathlib import Path
from subprocess import check_output, run, CompletedProcess

def get_ubuntu_theme_color() -> dict[str: str | None]:
    """Return the theme and accent color of Ubuntu 24.04 (and above) appearance.
    
    see https://askubuntu.com/q/1555780/541417 for details.
    Special thanks to @Ajay for his answer.

    Written by Sun Bear https://askubuntu.com/users/541417/sun-bear
    """
    theme: str = (
        check_output(
            ["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"],
        )
        .decode("utf-8")
        .replace("'", "")
        .strip()
    )

    if "dark" in theme.casefold():
        css = "gtk-dark.css"
    else:
        css = "gtk.css"

    themes_path: Path = Path("/usr/share/themes")
    gtk_path: Path = themes_path / theme / "gtk-4.0"
    gtk_css_file: Path = gtk_path / css
    gtk_gresource_file: Path = gtk_path / "gtk.gresource"

    resource_path: str = (
        check_output(
            ["cat", str(gtk_css_file)],
        )
        .decode("utf-8")
        .replace("'", "")
        .strip()
        .replace('@import url("resource://', "")
        .replace('");', "")
    )

    ubuntu_gtk_theme: CompletedProcess = run(
        ["gresource", "extract", str(gtk_gresource_file), str(resource_path)],
        capture_output=True,
        text=True,
    )

    color = None
    for line in ubuntu_gtk_theme.stdout.split("\n"):
        if "theme_selected_bg_color" in line:
            start = line.index("#")
            color = line[start:start+7]

    return theme, color


if __name__ == "__main__":

    theme_color: dict[str: str | None] = get_ubuntu_theme_color()
    print(theme_color[0])
    print(theme_color[1])

# $ gsettings get org.gnome.desktop.interface gtk-theme
# 'Yaru-purple-dark'
# $ ls /usr/share/themes/Yaru-purple-dark/gtk-4.0/
# gtk-dark.css  gtk.css  gtk.gresource
# $ cat /usr/share/themes/Yaru-purple-dark/gtk-4.0/gtk-dark.css
# @import url("resource:///com/ubuntu/themes/Yaru-purple-dark/4.0/gtk-dark.css")
# $ gresource extract /usr/share/themes/Yaru-purple-dark/gtk-4.0/gtk.gresource /com/ubuntu/themes/Yaru-purple-dark/4.0/gtk-dark.css > ~/Yaru-purple-dark.css
