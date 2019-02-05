# Copy some overrides to a well-known location
user_settings_dir=/home/jovyan/.jupyter/lab/user-settings
theme_settings="$user_settings_dir/@jupyterlab/apputils-extension/themes.jupyterlab-settings"

mkdir -p "$(dirname "$theme_settings")"
cat >"$theme_settings" <<EOF
{
    // Override default theme
    "theme": "Chameleon"
}
EOF
