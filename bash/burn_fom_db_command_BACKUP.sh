#!/bin/bash

# -----------------------------------------------
# 🛠️  CONFIGURACIÓN Y VALIDACIÓN INICIAL
# -----------------------------------------------

# Verificar si se proporciona un argumento (_id)
if [ -z "$1" ]; then
  echo "Uso: $0 <_id>"
  exit 1
fi

# Capturar el _id del primer parámetro posicional
ID="$1"

# Definir rutas principales
DATABASE_FILE="$HOME/repos/SmallFFmpegLocal/assets/databases/contacts.db"
LOCAL_ASSETS="$HOME/repos/SmallFFmpegLocal/assets"
REMOTE_FOLDER="/data/user/0/com.notimation.small/files"
COMMANDS_DIR="$HOME/repos/SmallFFmpegLocal/commands"  # Carpeta donde se guardan los comandos ejecutados

# -----------------------------------------------
# 🔍  BUSCAR EL EJECUTABLE EN LA CARPETA Debug O Release
# -----------------------------------------------

# Definir modo de compilación (Debug por defecto)
MODE="Debug"

# Verificar si se pasó el flag --release
if [[ "$2" == "--release" ]]; then
    MODE="Release"
    shift  # Eliminar el flag de los argumentos
fi

# Buscar la carpeta correcta dentro de DerivedData
EXECUTABLE_DIR=""
echo "Buscando en DerivedData para el modo: $MODE..."
for DIR in "$HOME/Library/Developer/Xcode/DerivedData"/SmallFFmpegLocal-*; do
    BUILD_PATH="$DIR/Build/Products/$MODE"
    
    echo "Buscando en: $BUILD_PATH"  # Mostrar cada carpeta encontrada

    if [ -d "$BUILD_PATH" ]; then
        EXECUTABLE_DIR="$BUILD_PATH"
        break  # Tomamos la primera versión encontrada
    fi
done

# Si no se encontró la carpeta, intentamos compilar
if [ -z "$EXECUTABLE_DIR" ]; then
    echo "No se encontró la carpeta $MODE en DerivedData. Iniciando compilación..."

    # Ejecutar compilación
    if [ "$MODE" == "Debug" ]; then
        xcodebuild -scheme SmallFFmpegApp -configuration Debug -derivedDataPath ./build build
    else
        xcodebuild -scheme SmallFFmpegApp -configuration Release -derivedDataPath ./build build
    fi

    # Buscar nuevamente el ejecutable después de la compilación
    for DIR in "$HOME/Library/Developer/Xcode/DerivedData"/SmallFFmpegLocal-*; do
        BUILD_PATH="$DIR/Build/Products/$MODE"
        if [ -d "$BUILD_PATH" ]; then
            EXECUTABLE_DIR="$BUILD_PATH"
            break
        fi
    done
fi

# Verificar si se encontró el directorio del ejecutable
if [ -z "$EXECUTABLE_DIR" ]; then
    echo "Error: No se encontró el ejecutable después de la compilación."
    exit 1
fi

EXECUTABLE="$EXECUTABLE_DIR/SmallFFmpegLocal.app/Contents/MacOS/SmallFFmpegLocal"

# -----------------------------------------------
# 📥  CONSULTAR EL COMANDO EN LA BASE DE DATOS
# -----------------------------------------------

# Obtener el comando desde la base de datos basado en _id
COMMAND=$(sqlite3 "$DATABASE_FILE" "SELECT command FROM TBL_VIDEOS_COMMANDS WHERE _id = $ID;")

# Verificar si se encontró un comando válido
if [ -z "$COMMAND" ]; then
  echo "No se encontró ningún comando para _id: $ID"
  exit 1
fi

# -----------------------------------------------
# 🔄  MODIFICAR EL COMANDO PARA USAR RUTAS LOCALES
# -----------------------------------------------

# Reemplazar rutas remotas con rutas locales
UPDATED_COMMAND=$(echo "$COMMAND" | sed "s|$REMOTE_FOLDER|$LOCAL_ASSETS|g")

# Extraer la última ruta de archivo .mp4 del comando y renombrarla con una marca de tiempo
LAST_MP4=$(echo "$UPDATED_COMMAND" | grep -oE '[^ ]+\.mp4' | tail -n1)
TIME=$(date +"%Y%m%d_%H%M%S")

if [ -n "$LAST_MP4" ]; then
  RENAMED_MP4="${LAST_MP4%.mp4}_$TIME.mp4"
  UPDATED_COMMAND=$(echo "$UPDATED_COMMAND" | sed "s|$LAST_MP4|$RENAMED_MP4|")
fi

# -----------------------------------------------
# 📂  GUARDAR EL COMANDO MODIFICADO EN UN ARCHIVO
# -----------------------------------------------

COMMAND_FILE="$COMMANDS_DIR/$(basename "$RENAMED_MP4" .mp4).txt"
CLEANED_COMMAND=$(echo "$UPDATED_COMMAND" | sed 's/^y-//; s/; */;/g')

# Guardar el comando en un archivo de texto
echo "$CLEANED_COMMAND" > "$COMMAND_FILE"

# Verificar si el archivo se guardó correctamente
if [ ! -s "$COMMAND_FILE" ]; then
    echo "Error: No se pudo guardar el comando en $COMMAND_FILE"
    exit 1
fi

# -----------------------------------------------
# 📋  COPIAR EL COMANDO EN EL PORTAPAPELES
# -----------------------------------------------

echo "$UPDATED_COMMAND" | pbcopy

# -----------------------------------------------
# 🚀  EJECUTAR LA APLICACIÓN CON EL COMANDO MODIFICADO
# -----------------------------------------------

# Cambiar al directorio del ejecutable y ejecutarlo
cd "$EXECUTABLE_DIR" || { echo "Error: No se pudo cambiar al directorio $EXECUTABLE_DIR"; exit 1; }

echo "Ejecutando aplicación con comando en el portapapeles"
"$EXECUTABLE" &

# Capturar el ID del proceso para poder finalizarlo después
PID=$!

# Esperar a que la aplicación termine
wait $PID

# -----------------------------------------------
# 🎬  ABRIR EL VIDEO GENERADO (SI EXISTE)
# -----------------------------------------------

if [ -f "$RENAMED_MP4" ]; then
  echo "Abriendo el video: $RENAMED_MP4"
  open "$RENAMED_MP4"
  sleep 2  # Dar tiempo al reproductor para que se inicie
fi

# -----------------------------------------------
# ❌  FINALIZAR PROCESO SmallFFmpegLocal
# -----------------------------------------------

pkill -f "SmallFFmpegLocal"
