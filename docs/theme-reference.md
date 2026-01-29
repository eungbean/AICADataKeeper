# Theme Reference for AICADataKeeper TUI

## OC-1 Dark Theme (opencode default)

Source: `/data/opencode/packages/ui/src/theme/themes/oc-1.json`

### Core Colors (Hex)

| Category | Color | Hex | Description |
|----------|-------|-----|-------------|
| **Background** | | | |
| background-base | ![#1a1817](https://via.placeholder.com/15/1a1817/1a1817.png) | `#1a1817` | Main background (almost black) |
| background-weak | ![#1c1717](https://via.placeholder.com/15/1c1717/1c1717.png) | `#1c1717` | Slightly lighter |
| background-strong | ![#151313](https://via.placeholder.com/15/151313/151313.png) | `#151313` | Darker areas |
| **Accent** | | | |
| primary | ![#fab283](https://via.placeholder.com/15/fab283/fab283.png) | `#fab283` | Peach/Orange (main accent) |
| interactive | ![#034cff](https://via.placeholder.com/15/034cff/034cff.png) | `#034cff` | Blue (links, buttons) |
| **Status** | | | |
| success | ![#12c905](https://via.placeholder.com/15/12c905/12c905.png) | `#12c905` | Green (checkmarks) |
| warning | ![#fcd53a](https://via.placeholder.com/15/fcd53a/fcd53a.png) | `#fcd53a` | Yellow (warnings) |
| error | ![#fc533a](https://via.placeholder.com/15/fc533a/fc533a.png) | `#fc533a` | Red-orange (errors) |
| info | ![#edb2f1](https://via.placeholder.com/15/edb2f1/edb2f1.png) | `#edb2f1` | Light purple |
| **Neutral/Text** | | | |
| neutral | ![#716c6b](https://via.placeholder.com/15/716c6b/716c6b.png) | `#716c6b` | Gray (borders, muted) |
| text-base | ![#e8e2df](https://via.placeholder.com/15/e8e2df/e8e2df.png) | `#e8e2df` | Main text (off-white) |
| text-weak | ![#a09895](https://via.placeholder.com/15/a09895/a09895.png) | `#a09895` | Muted text |
| **Diff** | | | |
| diffAdd | ![#c8ffc4](https://via.placeholder.com/15/c8ffc4/c8ffc4.png) | `#c8ffc4` | Added lines |
| diffDelete | ![#fc533a](https://via.placeholder.com/15/fc533a/fc533a.png) | `#fc533a` | Deleted lines |

### ANSI 256-Color Equivalents (for Bash)

```bash
# Background (use terminal default black, or these approximations)
# #1a1817 ≈ 234 (gray4)
# #151313 ≈ 233 (gray3)

# Theme Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'

# Primary/Accent
C_PRIMARY='\033[38;5;216m'    # #fab283 (peach) - closest: 216
C_BLUE='\033[38;5;27m'        # #034cff (blue) - closest: 27

# Text
C_TEXT='\033[38;5;252m'       # #e8e2df (off-white) - closest: 252
C_MUTED='\033[38;5;245m'      # #a09895 (gray) - closest: 245
C_BOX='\033[38;5;241m'        # #716c6b (border gray) - closest: 241

# Status
C_SUCCESS='\033[38;5;40m'     # #12c905 (green) - closest: 40
C_WARNING='\033[38;5;220m'    # #fcd53a (yellow) - closest: 220
C_ERROR='\033[38;5;203m'      # #fc533a (red-orange) - closest: 203

# Backgrounds (for selections, boxes)
C_BG_BOX='\033[48;5;236m'     # Dark gray box background
C_BG_SELECT='\033[48;5;238m'  # Selection highlight
```

### Dialog/Whiptail Theming

**Option 1: Force text mode** (uses ANSI colors above)
```bash
# In main.sh, change line 128:
DIALOG_CMD="text"
# Comment out the if/elif block for dialog/whiptail detection
```

**Option 2: Install dialog + custom dialogrc**
```bash
sudo apt install dialog

# Create ~/.dialogrc or /etc/dialogrc
cat > ~/.dialogrc << 'EOF'
# OC-1 Dark Theme for dialog
use_shadow = OFF
use_colors = ON

# Screen (background)
screen_color = (WHITE,BLACK,OFF)

# Dialog box
dialog_color = (WHITE,BLACK,OFF)

# Title
title_color = (YELLOW,BLACK,ON)

# Border
border_color = (WHITE,BLACK,OFF)

# Button (inactive)
button_inactive_color = (WHITE,BLACK,OFF)

# Button (active/selected)  
button_active_color = (BLACK,WHITE,ON)

# Input box
inputbox_color = (WHITE,BLACK,OFF)

# Menu items
menubox_color = (WHITE,BLACK,OFF)
menubox_border_color = (WHITE,BLACK,OFF)

# Selected item
item_selected_color = (BLACK,YELLOW,ON)
tag_selected_color = (BLACK,YELLOW,ON)

# Tag (number/key)
tag_color = (YELLOW,BLACK,OFF)
tag_key_color = (YELLOW,BLACK,ON)
EOF
```

**Option 3: Use newt/whiptail with NEWT_COLORS**
```bash
# Set before running whiptail
export NEWT_COLORS='
  root=white,black
  window=white,black
  border=white,black
  shadow=black,black
  title=yellow,black
  button=black,white
  actbutton=black,yellow
  checkbox=white,black
  actcheckbox=black,yellow
  entry=white,black
  label=white,black
  listbox=white,black
  actlistbox=black,yellow
  textbox=white,black
  acttextbox=black,yellow
  helpline=white,black
  roottext=yellow,black
'
```

---

## Other Available Themes

Location: `/data/opencode/packages/ui/src/theme/themes/`

| Theme | Style | Key Colors |
|-------|-------|------------|
| `dracula.json` | Purple dark | Purple, Pink, Cyan |
| `nord.json` | Arctic blue | Blue-gray, Frost blue |
| `gruvbox.json` | Retro warm | Orange, Brown, Beige |
| `catppuccin.json` | Pastel dark | Mauve, Pink, Sky |
| `tokyonight.json` | Neon blue | Electric blue, Purple |
| `monokai.json` | Classic dark | Yellow, Pink, Green |
| `vesper.json` | Minimal | Peach, Cream |
| `solarized.json` | Low contrast | Blue, Cyan, Green |
| `aura.json` | Purple glow | Purple, Orange |
| `onedarkpro.json` | Atom-like | Cyan, Magenta |

---

## Usage in main.sh

Current implementation location: `/data/AICADataKeeper/main.sh` lines 11-25

To apply OC-1 theme with text mode:
1. Keep current color definitions (already OC-1 inspired)
2. Force `DIALOG_CMD="text"` at line 128
3. The box-drawing menus at lines 767-786 and 1070-1082 will display

---

*Generated: 2026-01-29*
*Source: opencode themes @ /data/opencode/packages/ui/src/theme/themes/*
