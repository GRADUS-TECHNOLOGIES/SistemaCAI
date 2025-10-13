# ==============================================================
# 🤖 GIT WORKFLOW MANAGER - SISTEMACAI
# ==============================================================

# ===========================
# LOCALIZAR ROOT DEL REPO
# ===========================
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$ROOT_DIR" ]; then
    echo -e "\033[0;31m❌ Error: No se detectó un repositorio Git.\033[0m"
    exit 1
fi

cd "$ROOT_DIR" || exit 1

# ===========================
# CARGAR CONFIGURACIÓN
# ===========================
CONFIG_FILE="$ROOT_DIR/.git-workflow-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "\033[1;33m⚠️ No se encontró .git-workflow-config. Usando valores por defecto.\033[0m"
    RAMA_PRINCIPAL="main"
    RAMA_DESARROLLO="develop"
    RAMA_TESTEO="testing"
    RAMAS_FEATURE=("feature/jorge" "feature/zavaleta")
    COMANDO_TESTEO="npm run dev"
    COMANDO_CONSTRUCCION="npm run build"
fi

# ===========================
# COLORES
# ===========================
BLANCO="\033[1;37m"
VERDE="\033[1;32m"
ROJO="\033[1;31m"
AMARILLO="\033[1;33m"
AZUL="\033[1;34m"
CYAN="\033[1;36m"
MORADO="\033[1;35m" 
SC="\033[0m"

# ===========================
# ESTILOS DE TEXTO
# ===========================
FONDO_NEGRO="\033[40m"
BLANCO_SUBRAYADO="\033[4;37m"

# ===========================
# RUTAS
# ===========================
CLIENT_DIR="$ROOT_DIR/client"

# ===========================
# FUNCIONES
# ===========================

mostrar_status() {
    echo -e "\n${AZUL}=== ESTADO ACTUAL DE RAMAS ===${SC}"
    git branch -avv
    echo -e "${AZUL}===============================${SC}\n"
}

actualizar_rama_base () {
    local branch=$1
    echo -e "${AMARILLO}Actualizando $branch...${SC}"
    git checkout "$branch" >/dev/null 2>&1
    git pull origin "$branch"
    if [ $? -ne 0 ]; then
        echo -e "${ROJO}❌ Error al actualizar $branch${SC}"
        return 1
    fi
    echo -e "${VERDE}✅ $branch actualizada correctamente${SC}"
}

test_feature () {
    local feature=$1
    echo -e "\n${AZUL}🧪 TESTEANDO: $feature${SC}"

    actualizar_rama_base "$RAMA_DESARROLLO" || return 1

    git checkout "$feature" >/dev/null 2>&1
    git pull origin "$feature"

    git merge "$RAMA_DESARROLLO" --no-edit

    echo -e "${AMARILLO}🚀 Ejecutando testeo...${SC}"

    if [ -d "$CLIENT_DIR" ]; then
        cd "$CLIENT_DIR" || exit 1
        if [ -f "package.json" ]; then
            echo -e "${AMARILLO}📦 Instalando dependencias...${SC}"
            npm install --silent
            echo -e "${AMARILLO}⚙️ Construyendo proyecto...${SC}"
            eval "$COMANDO_CONSTRUCCION" || {
                echo -e "${ROJO}❌ Error en npm run build${SC}"
                cd "$ROOT_DIR" || exit 1
                return 1
            }
            echo -e "${AMARILLO}🧭 Ejecutando tests (npm run dev)...${SC}"
            eval "$COMANDO_TESTEO"
            cd "$ROOT_DIR" || exit 1
        else
            echo -e "${ROJO}❌ No se encontró package.json dentro de client/${SC}"
            return 1
        fi
    else
        echo -e "${ROJO}❌ No se encontró la carpeta client/${SC}"
        return 1
    fi

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✅ Tests pasados en $feature${SC}"
        return 0
    else
        echo -e "${ROJO}❌ Tests fallaron en $feature${SC}"
        return 1
    fi
}

push_feature() {
    local feature=$1
    echo -e "\n${AZUL}🚀 HACIENDO PUSH: $feature${SC}"

    git checkout "$feature" >/dev/null 2>&1
    git push origin "$feature"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✅ Push exitoso de $feature${SC}"
    else
        echo -e "${ROJO}❌ Error en push de $feature${SC}"
    fi
}

merge_testing () {
    local feature=$1
    echo -e "\n${AZUL}🔄 MERGE A TESTING: $feature${SC}"

    actualizar_rama_base "$RAMA_TESTEO" || return 1

    git merge "$feature" --no-edit || {
        echo -e "${ROJO}⚠️ Conflictos detectados al fusionar $feature con $RAMA_TESTEO${SC}"
        echo -e "${AMARILLO}Por favor resuélvelos manualmente y haz push.${SC}"
        return 1
    }

    git push origin "$RAMA_TESTEO"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}✅ $feature fusionado a testing${SC}"
    else
        echo -e "${ROJO}❌ Error fusionando $feature a testing${SC}"
    fi
}

workflow_feature () {
    local feature=$1
    echo -e "\n${AZUL}🎯 INICIANDO WORKFLOW PARA: $feature${SC}"

    test_feature "$feature" && \
    push_feature "$feature" && \
    merge_testing "$feature"

    if [ $? -eq 0 ]; then
        echo -e "${VERDE}🎉 Workflow completado para $feature${SC}"
    else
        echo -e "${ROJO}💥 Workflow falló para $feature${SC}"
    fi
}

# ===========================
# MENÚ PRINCIPAL
# ===========================
case "$1" in
    "status")
        mostrar_status
        ;;
    "test")
        if [ -z "$2" ]; then
            echo -e "${AMARILLO}Testeando todas las features...${SC}"
            for feature in "${RAMAS_FEATURE[@]}"; do
                test_feature "$feature"
            done
        else
            test_feature "$2"
        fi
        ;;
    "push")
        if [ -z "$2" ]; then
            for feature in "${RAMAS_FEATURE[@]}"; do
                push_feature "$feature"
            done
        else
            push_feature "$2"
        fi
        ;;
    "merge-testing")
        if [ -z "$2" ]; then
            for feature in "${RAMAS_FEATURE[@]}"; do
                merge_testing "$feature"
            done
        else
            merge_testing "$2"
        fi
        ;;
    "workflow")
        if [ -z "$2" ]; then
            for feature in "${RAMAS_FEATURE[@]}"; do
                workflow_feature "$feature"
            done
        else
            workflow_feature "$2"
        fi
        ;;
    "update-all")
        echo -e "${AMARILLO}Actualizando ramas base...${SC}"
        actualizar_rama_base "$RAMA_PRINCIPAL"
        actualizar_rama_base "$RAMA_DESARROLLO"
        actualizar_rama_base "$RAMA_TESTEO"
        ;;
    *)
        echo -e "${MORADO}      #####${AMARILLO}   #####${CYAN}   #####${VERDE}   #####${ROJO}   #####   ${SC}${FONDO_NEGRO} 🤖 GIT WORKFLOW MANAGER 🤖 ${SC}"
        echo -e "${MORADO}     ##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##   ${SC}"
        echo -e "${MORADO}    ##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##   ${BLANCO} COMANDOS DISPONIBLES:${SC}"
        echo -e "${MORADO}   ##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##       ${BLANCO}status${SC} (Muestra el estado de las ramas)"
        echo -e "${MORADO}  ##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##        ${BLANCO}test${SC} (Ejecuta tests en feature)"
        echo -e "${MORADO} ##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##         ${BLANCO}merge-testing${SC} (Merge a testing)"
        echo -e "${MORADO}##  ##${AMARILLO}  ##  ##${CYAN}  ##  ##${VERDE}  ##  ##${ROJO}  ##  ##          ${BLANCO}workflow${SC} (Workflow completo)"
        echo -e "${MORADO}####${AMARILLO}    ####${CYAN}    ####${VERDE}    ####${ROJO}    ####            ${BLANCO}update-all${SC} (Actualiza todas las ramas base)"
        echo ""
        echo -e "${AZUL}Ejemplos:${SC}"
        echo -e "  ${BLANCO_SUBRAYADO}git-flow workflow feature/jorge${SC}"
        echo -e "  ${BLANCO_SUBRAYADO}git-flow test feature/zavaleta${SC}"
        echo -e "  ${BLANCO_SUBRAYADO}git-flow merge-testing${SC}"
        ;;
esac
