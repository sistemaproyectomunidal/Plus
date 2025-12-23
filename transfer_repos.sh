#!/bin/bash

# Script para transferir y borrar repositorios de GitHub
# Requiere:  gh CLI (GitHub CLI) instalado y autenticado

set -e  # Salir si hay errores

# Configuración
CURRENT_OWNER="sistemaproyectomunidal"
REPO1="PlatonIA2v"
REPO2="Porterias"
NEW_OWNER="albertomayday"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Script de Transferencia y Eliminación de Repositorios ===${NC}\n"

# Verificar que se especificó el nuevo propietario
if [ -z "$NEW_OWNER" ]; then
    echo -e "${RED}ERROR: Debes especificar NEW_OWNER en el script${NC}"
    exit 1
fi

# Verificar que gh CLI está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}ERROR: GitHub CLI (gh) no está instalado${NC}"
    echo "Instálalo desde:  https://cli.github.com/"
    exit 1
fi

# Función para transferir repositorio
transfer_repo() {
    local repo=$1
    echo -e "${YELLOW}Transfiriendo $CURRENT_OWNER/$repo a $NEW_OWNER...${NC}"
    
    gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$CURRENT_OWNER/$repo/transfer" \
        -f new_owner="$NEW_OWNER"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Repositorio $repo transferido exitosamente${NC}\n"
        return 0
    fi
}

# Función para verificar que el repositorio existe en la nueva ubicación
verify_transfer() {
    local repo=$1
    echo -e "${YELLOW}Verificando transferencia de $repo...${NC}"
    
    sleep 5  # Esperar un poco para que se complete la transferencia
    
    gh repo view "$NEW_OWNER/$repo" &> /dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Repositorio $repo confirmado en $NEW_OWNER${NC}\n"
        return 0
    else
        echo -e "${RED}✗ No se pudo verificar $repo en $NEW_OWNER${NC}\n"
        return 1
    fi
}

# Función para eliminar repositorio de la ubicación original
delete_repo() {
    local repo=$1
    echo -e "${YELLOW}Eliminando $CURRENT_OWNER/$repo...${NC}"
    
    gh repo delete "$CURRENT_OWNER/$repo" --yes
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Repositorio $repo eliminado exitosamente${NC}\n"
        return 0
    else
        echo -e "${RED}✗ Error al eliminar $repo (puede que ya no exista en la cuenta original)${NC}\n"
        return 0  # No es error crítico si ya fue transferido
    fi
}

# Procesar primer repositorio
echo -e "${GREEN}=== Procesando $REPO1 ===${NC}"
if transfer_repo "$REPO1"; then
    if verify_transfer "$REPO1"; then
        echo -e "${YELLOW}¿Confirmar eliminación de $CURRENT_OWNER/$REPO1?  (s/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            delete_repo "$REPO1"
        else
            echo -e "${YELLOW}Eliminación de $REPO1 cancelada${NC}\n"
        fi
    else
        echo -e "${RED}No se eliminará $REPO1 porque no se pudo verificar la transferencia${NC}\n"
    fi
else
    echo -e "${RED}No se pudo transferir $REPO1${NC}\n"
fi

# Procesar segundo repositorio
echo -e "${GREEN}=== Procesando $REPO2 ===${NC}"
if transfer_repo "$REPO2"; then
    if verify_transfer "$REPO2"; then
        echo -e "${YELLOW}¿Confirmar eliminación de $CURRENT_OWNER/$REPO2?  (s/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Ss]$ ]]; then
            delete_repo "$REPO2"
        else
            echo -e "${YELLOW}Eliminación de $REPO2 cancelada${NC}\n"
        fi
    else
        echo -e "${RED}No se eliminará $REPO2 porque no se pudo verificar la transferencia${NC}\n"
    fi
else
    echo -e "${RED}No se pudo transferir $REPO2${NC}\n"
fi

echo -e "${GREEN}=== Proceso completado ===${NC}"
