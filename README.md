Ferramenta Universal de Reset para IDEs
Uma ferramenta em PowerShell que suporta múltiplas IDEs (Cursor/VS Code) e limpeza de extensões, capaz de redefinir identificadores de dispositivo e limpar dados de extensões para simular um novo usuário.

🚀 Como Usar
Requisitos
Sistema Windows

Permissões de administrador (obrigatório)

IDE alvo instalada (Cursor ou VS Code)

🎯 Modos de Uso
🚀 Execução Direta (Recomendado)
powershell
# Execute o PowerShell como administrador e depois:
irm https://raw.githubusercontent.com/Ramys/Cursor-Ramys/refs/heads/main/ide-reset-ultimate.ps1 | iex x
✨ Funcionalidades:

🎯 Suporte a Múltiplas IDEs: Cursor + VS Code

🧩 Limpeza Inteligente de Extensões: Limpeza profunda do Augment + outras extensões

🎨 Compatibilidade com Cores: Adapta-se automaticamente a qualquer ambiente PowerShell

🔍 Modo de Simulação: Visualiza ações sem executá-las

🚀 Reinício Automático: Opção de reiniciar a IDE após conclusão

🛡️ Configurações Preservadas: Preferências e configurações do usuário são mantidas

🔧 Execução Local
powershell
# Download
irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/cursor-free-vip/main/ide-reset-ultimate.ps1 -OutFile ide-reset-ultimate.ps1
.\ide-reset-ultimate.ps1

# Ou clone o projeto
git clone https://github.com/Huo-zai-feng-lang-li/cursor-free-vip.git
cd cursor-free-vip
.\ide-reset-ultimate.ps1
🚀 Características
🎯 Suporte a Múltiplas IDEs: Cursor + VS Code

🧩 Limpeza de Extensões: Augment, GitHub Copilot, Codeium, etc.

🔍 Modo de Simulação: Visualiza ações sem executá-las

🛡️ Backup Automático: Faz backup de configurações importantes

🔄 Redefinição de Dispositivo: Gera novos identificadores

🗂️ Modificação de Registro: Atualiza o MachineGuid do sistema

🗑️ Limpeza de Histórico: Remove histórico mas mantém configurações

🚫 Controle de Atualizações: Opção para desativar atualizações automáticas (Cursor)

🌐 Limpeza de Rede: Opção para limpar cache DNS e resetar protocolos de rede

🚀 Reinício Automático: Reinicia a IDE após a conclusão

🎨 Compatibilidade com Cores: Detecta suporte a cores do terminal

⚠️ Avisos
Riscos
Modifica o registro do sistema (requer admin)

Limpa histórico e dados de workspace da IDE

Limpa dados de extensões (simula novo usuário)

Pode violar termos de uso do software

Alguns antivírus podem detectar como falso positivo

Recomendações
Simule Primeiro: Use o modo de simulação para ver as ações

Backup: Faça backup de configurações e projetos importantes

Ambiente de Teste: Teste primeiro em um ambiente não crítico

📊 Detalhes da Limpeza
Diagram
Code

🧹 Processo de Limpeza
1. Limpeza de Histórico (Mantém Configurações)
state.vscdb - Banco de dados de estado

Histórico - Arquivos e projetos recentes

workspaceStorage - Dados de workspace

logs - Registros de erro

2. Limpeza de Extensões (Simula Novo Usuário)
Augment - Limpeza profunda

🎯 SessionID - Identificadores únicos

🔄 Rastreamento - Variáveis de ambiente, hardware

📊 Monitoramento - Dados de análise

🗑️ Git - Informações de repositório

🛡️ Configurações - Preferências mantidas

GitHub Copilot - Limpeza total

Codeium - Limpeza total

3. Dados Preservados
settings.json - Configurações

keybindings.json - Atalhos

snippets - Trechos de código

themes - Temas

extensions - Extensões instaladas

🏗️ Arquitetura
Diagram
Code

📁 Arquivos do Projeto
text
cursor-free-vip/
├── README.md                 # Documentação
└── ide-reset-ultimate.ps1    # 🌟 (Único arquivo)
📄 Isenção de Responsabilidade
Para fins educacionais apenas

Use por sua conta e risco



Pode violar termos de uso

Sem garantias ou suporte

Proibido uso comercial
