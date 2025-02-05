#!/bin/bash

# -----------------------------------------------
# �️  CONFIGURACIÓN Y VALIDACIÓN INICIAL
# -----------------------------------------------

if [ -z "$1" ]; then
  echo "Uso: $0 <_id>"
  exit 1
fi

ID="$1"
DATABASE_FILE="$HOME/repos/SmallFFmpegLocal/assets/databases/contacts.db"
LOCAL_ASSETS="$HOME/repos/SmallFFmpegLocal/assets"
REMOTE_FOLDER="/data/user/0/com.notimation.small/files"
COMMANDS_DIR="$HOME/repos/SmallFFmpegLocal/commands"

# -----------------------------------------------
# �  BUSCAR EL EJECUTABLE EN LA CARPETA Debug O Release
# -----------------------------------------------

MODE="Debug"
if [[ "$2" == "--release" ]]; then
    MODE="Release"
    shift
fi

EXECUTABLE_DIR=""
echo "Buscando en DerivedData para el modo: $MODE..."
for DIR in "$HOME/Library/Developer/Xcode/DerivedData"/SmallFFmpegLocal-*; do
    BUILD_PATH="$DIR/Build/Products/$MODE"
    echo "Buscando en: $BUILD_PATH"
    if [ -d "$BUILD_PATH" ]; then
        EXECUTABLE_DIR="$BUILD_PATH"
        break
    fi
done

if [ -z "$EXECUTABLE_DIR" ]; then
    echo "No se encontró la carpeta $MODE en DerivedData. Iniciando compilación..."
    if [ "$MODE" == "Debug" ]; then
        xcodebuild -scheme SmallFFmpegApp -configuration Debug -derivedDataPath ./build build
    else
        xcodebuild -scheme SmallFFmpegApp -configuration Release -derivedDataPath ./build build
    fi

    for DIR in "$HOME/Library/Developer/Xcode/DerivedData"/SmallFFmpegLocal-*; do
        BUILD_PATH="$DIR/Build/Products/$MODE"
        if [ -d "$BUILD_PATH" ]; then
            EXECUTABLE_DIR="$BUILD_PATH"
            break
        fi
    done
fi

if [ -z "$EXECUTABLE_DIR" ]; then
    echo "Error: No se encontró el ejecutable después de la compilación."
    exit 1
fi

EXECUTABLE="$EXECUTABLE_DIR/SmallFFmpegLocal.app/Contents/MacOS/SmallFFmpegLocal"

# -----------------------------------------------
# �  CONSULTAR EL COMANDO EN LA BASE DE DATOS
# -----------------------------------------------

COMMAND=$(sqlite3 "$DATABASE_FILE" "SELECT command FROM TBL_VIDEOS_COMMANDS WHERE _id = $ID;")

if [ -z "$COMMAND" ]; then
  echo "No se encontró ningún comando para _id: $ID"
  exit 1
fi

# -----------------------------------------------
# �  MODIFICAR EL COMANDO PARA USAR RUTAS LOCALES
# -----------------------------------------------

UPDATED_COMMAND=$(echo "$COMMAND" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sed "s|$REMOTE_FOLDER|$LOCAL_ASSETS|g")

# Agregar el parámetro -y para sobrescribir el archivo de salida
UPDATED_COMMAND="$UPDATED_COMMAND -y"

LAST_MP4=$(echo "$UPDATED_COMMAND" | grep -oE '[^ ]+\.mp4' | tail -n1)
TIME=$(date +"%Y%m%d_%H%M%S")

if [ -n "$LAST_MP4" ]; then
  RENAMED_MP4="${LAST_MP4%.mp4}_$TIME.mp4"
  UPDATED_COMMAND=$(echo "$UPDATED_COMMAND" | sed "s|$LAST_MP4|$RENAMED_MP4|")
fi

# -----------------------------------------------
# �  GUARDAR EL COMANDO MODIFICADO EN UN ARCHIVO
# -----------------------------------------------

COMMAND_FILE="$COMMANDS_DIR/$(basename "$RENAMED_MP4" .mp4).txt"
CLEANED_COMMAND=$(printf "%s" "$UPDATED_COMMAND" | sed 's/^y-//; s/; */;/g')

echo "$CLEANED_COMMAND" > "$COMMAND_FILE"

if [ ! -s "$COMMAND_FILE" ]; then
    echo "Error: No se pudo guardar el comando en $COMMAND_FILE"
    exit 1
fi

# -----------------------------------------------
# �  COPIAR EL COMANDO EN EL PORTAPAPELES
# -----------------------------------------------

echo -n "$UPDATED_COMMAND" | pbcopy

# -----------------------------------------------
# �  EJECUTAR LA APLICACIÓN CON EL COMANDO MODIFICADO
# -----------------------------------------------

cd "$EXECUTABLE_DIR" || { echo "Error: No se pudo cambiar al directorio $EXECUTABLE_DIR"; exit 1; }

echo "Comando generado: [$UPDATED_COMMAND]"
echo "Ejecutando aplicación con comando en el portapapeles"
"$EXECUTABLE" &

PID=$!
wait $PID

# -----------------------------------------------
# �  ABRIR EL VIDEO GENERADO (SI EXISTE)
# -----------------------------------------------

if [ -f "$RENAMED_MP4" ]; then
  echo "Abriendo el video: $RENAMED_MP4"
  open "$RENAMED_MP4"
  sleep 2
fi

# -----------------------------------------------
# ❌  FINALIZAR PROCESO SmallFFmpegLocal
# -----------------------------------------------

pkill -f "SmallFFmpegLocal"