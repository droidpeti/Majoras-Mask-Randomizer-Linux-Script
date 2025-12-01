#!/bin/bash

# --- CONFIGURATION ---
# You can change these paths freely; the launcher will update automatically.
INSTALL_DIR="$HOME/MajoraRandomizer"
PREFIX_DIR="$HOME/.mmr_prefix"

# URLs
DOTNET_URL="https://download.visualstudio.microsoft.com/download/pr/4c24a668-e696-412d-905e-6537c3588267/3807205423853112a230559f97626920/windowsdesktop-runtime-5.0.17-win-x64.exe"
MMR_RELEASE_URL="https://github.com/ZoeyZolotova/mm-rando/releases/latest/download/MM-Randomizer-v1.16.0.12.zip"

echo "Majora's Mask Randomizer Linux Setup"
echo "Target Directory: $INSTALL_DIR"
echo "Wine Prefix:      $PREFIX_DIR"
echo "--------------------------------------------"

# 1. Check Dependencies
echo "[+] Checking dependencies..."
for cmd in wine winetricks curl unzip; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: '$cmd' is not installed. Please install it first."
        exit 1
    fi
done

# 2. Create Directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# 3. Setup Wine Prefix
if [ -d "$PREFIX_DIR" ]; then
    echo "[!] Prefix exists. Skipping creation."
else
    echo "[+] Creating clean Wine Prefix (64-bit)..."
    WINEDLLOVERRIDES="mscoree=" WINEPREFIX="$PREFIX_DIR" WINEARCH=win64 wineboot --init
fi

# 4. Download & Install .NET 5
if [ ! -f "$PREFIX_DIR/drive_c/Program Files/dotnet/dotnet.exe" ]; then
    echo "[+] Downloading .NET Desktop Runtime 5.0.17..."
    curl -L -o dotnet_installer.exe "$DOTNET_URL"

    echo "[+] Installing .NET 5 (Silent)..."
    DOTNET_ROOT="" WINEPREFIX="$PREFIX_DIR" wine dotnet_installer.exe /install /quiet /norestart
    
    echo "[+] Removing installer..."
    rm dotnet_installer.exe
else
    echo "[!] .NET 5 appears to be installed already."
fi

# 5. Fix UI Glitches
echo "[+] Applying 'Virtual Desktop' fix (1280x960)..."
WINEPREFIX="$PREFIX_DIR" winetricks vd=1280x960 > /dev/null 2>&1

# 6. Download Randomizer
if [ ! -f "MajoraRandomizer.exe" ] && [ ! -f "MM Randomizer.exe" ]; then
    echo "[+] Downloading Randomizer..."
    curl -L -o mmr.zip "$MMR_RELEASE_URL"
    echo "[+] Extracting..."
    unzip -o mmr.zip
    rm mmr.zip
fi

# 7. Create Launcher Script
echo "[+] Creating launch script..."
cat << EOF > launch_mmr.sh
#!/bin/bash
# Find the executable name (Handles spaces or renames)
EXE_NAME=\$(ls *.exe | grep -v "installer" | head -n 1)
PREFIX_DIR="$PREFIX_DIR"

# Run with .NET fix
echo "Launching \$EXE_NAME..."
DOTNET_ROOT="" WINEPREFIX="\$PREFIX_DIR" wine "\$EXE_NAME"
EOF

chmod +x launch_mmr.sh

echo "--------------------------------------------"
echo "SUCCESS! Setup complete."
echo "To play, run: cd \"$INSTALL_DIR\" && ./launch_mmr.sh"
