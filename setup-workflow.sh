# ===========================
# COPIAR EL SCRIPT PRINCIPAL
# ===========================
if [ ! -f git-workflow.sh ]; then
    echo "❌ No se encontró git-workflow.sh en este directorio."
    exit 1
fi

# ===========================
# HACER EJECUTABLE
# ===========================
chmod +x git-workflow.sh

# ===========================
# ALIAS PARA FACILIDAD DE USO
# ===========================
if ! grep -q "alias git-flow=" ~/.bashrc; then
    echo "alias git-flow='./git-workflow.sh'" >> ~/.bashrc
    echo "✅ Alias agregado a ~/.bashrc"
else
    echo "ℹ️ Alias ya existente en ~/.bashrc"
fi

echo "✅ Scripts configurados correctamente"
echo "📝 Reinicia tu terminal o ejecuta: source ~/.bashrc"
echo "🚀 Usa: git-flow [comando]"