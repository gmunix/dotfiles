export EDITOR=nvim

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

if [[ -d "$HOME/.spicetify" ]]; then
  case ":$PATH:" in
    *":$HOME/.spicetify:"*) ;;
    *) export PATH="$PATH:$HOME/.spicetify" ;;
  esac
fi
