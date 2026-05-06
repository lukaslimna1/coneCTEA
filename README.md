# ConeCTEA - Carteirinha Digital 🧩

O **ConeCTEA** é um ecossistema mobile desenvolvido em Flutter para a modernização do processo de identificação de pessoas com TEA (Transtorno do Espectro Autista). O foco central é a **Carteirinha Digital**, eliminando a necessidade de documentos físicos e simplificando a validação de direitos.

---

## 🎨 Identidade Visual (ConeCTEA)

Uma comunicação moderna, acessível e institucional que conecta inclusão, tecnologia e confiança.

### **1. Essência Visual**
*   **📡 Tecnológico**: Uso de elementos geométricos e profundidade.
*   **♿ Acessível**: Foco em contraste e tipografia limpa.
*   **🏛️ Institucional**: Cores sólidas e sobriedade nos textos primários.
*   **🧩 Acolhedor**: Gradientes suaves e design humanizado.

### **2. Paleta de Cores Oficial**
| Cor | Hex | Aplicação |
| :--- | :--- | :--- |
| **Azul Escuro** | `#0D1B4C` | Fundo principal, textos primários e cabeçalhos. |
| **Azul Vivo** | `#1E63D8` | Destaques secundários e ícones de navegação. |
| **Roxo** | `#8A44E8` | Base do gradiente da marca e botões de ação principal. |
| **Verde Água (Teal)** | `#4FD4C8` | Fim do gradiente e elementos de sucesso/ativação. |
| **Branco** | `#FFFFFF` | Superfícies, cards e legibilidade em fundos escuros. |

### **3. Elementos Gráficos & Design**
*   **Geometria**: Uso de formas diagonais para transmitir dinamismo.
*   **Profundidade**: Efeitos de *glassmorphism* e camadas sobre fundo azul escuro.
*   **Marca**: Gradiente Roxo + Teal aplicado ao logotipo e selos oficiais.
*   **QR Code**: Elemento central de validação, sempre com alto contraste.
*   **Tipografia**: Utilização da fonte **Inter** (limpa, moderna e forte).

### **4. Aplicação da Carteirinha Digital**
*   **Privacidade**: Sem foto do usuário (substituída por Selo Visual Dinâmico).
*   **Destaque**: Nome, Validade e Número da Carteira em hierarquia visual clara.
*   **Validação**: QR Code como motor principal de autenticidade.

### **5. Marcas Relacionadas**
*   **ConeCTEA** (Plataforma)
*   **Família TEA Bauru** (Idealização)
*   `#TODOSPELOAUTISMO` (Movimento)

---


## 📱 Foco em Mobile
Diferente de sistemas web genéricos, o ConeCTEA foi projetado exclusivamente como um **aplicativo nativo (Android)**.
- **Plataforma Alvo**: Android (Emulador ou Dispositivo Físico).
- **🚫 Sem Suporte Web**: O projeto não utiliza e não deve ser executado via Chrome/Web, garantindo maior segurança e integração com recursos nativos do sistema.

---

## 🪪 Nova Carteirinha Digital (Design "Member-Only")
A carteirinha digital foi totalmente reformulada para um padrão premium e profissional:
- **Design Horizontal**: Otimizado para visualização em tela cheia no celular.
- **Privacidade Total**: Não armazena fotos dos usuários. A identificação visual é feita por um **Selo Visual Dinâmico** com as iniciais do membro e ícones de acessibilidade.
- **Identidade Visual**: Tema *Deep Dark Blue* com elementos geométricos e acabamento em vidro (glassmorphism).
- **Validação via QR Code**: Gerado dinamicamente para consulta em tempo real da validade e autenticidade.
- **Badge de Membro**: Identificação clara do status de "ATIVO" e categoria "MEMBRO".

---

## 🧠 Acessibilidade Cognitiva
Seguindo princípios de acessibilidade e clareza visual, o app reforça a comunicação escrita com elementos visuais:
- **Semântica de Cores**: Uso rigoroso de cores para indicar status (ex: Verde = Aprovada, Amarelo = Em análise, Vermelho = Ajuste necessário).
- **Ícones de Apoio**: Cada status e ação crítica possui um ícone correspondente para facilitar a compreensão por pessoas com diferentes perfis de processamento cognitivo.
- **Interface Limpa**: Layouts organizados para reduzir a sobrecarga sensorial e cognitiva.

---

## ⚡ Sincronização e Performance
- **Atualização Dinâmica**: Telas críticas (como Minhas Solicitações e Detalhes da Carteirinha) utilizam Streams para refletir mudanças no Firestore sem necessidade de recarregar a página.
- **Eficiência de Recursos**: Uso inteligente de snapshots para evitar consumo desnecessário de leituras no banco de dados.
- **UX Responsiva**: Transições suaves e feedback imediato para todas as ações do usuário.

---

## 📋 Fluxo de Status (Mapeamento Ideal)

### 👁️ Para o Usuário
- 🟡 **Em análise**: Sua solicitação foi enviada e está sendo analisada.
- 🔵 **Aguardando contato**: A equipe vai chamar você pelo WhatsApp.
- 🟢 **Aprovada**: Sua carteirinha já está disponível.
- 🟠 **Precisa de ajuste**: Alguma informação precisa ser corrigida.
- 🔴 **Não aprovada**: A solicitação não foi aprovada neste momento.
- ⚫ **Vencida**: A carteirinha passou da validade.
- 🟣 **Renovação solicitada**: Seu pedido de renovação foi enviado.

### 🛠️ Para o Administrador
- **Pendente**: Nova solicitação recebida.
- **Em atendimento externo**: Necessário contato via WhatsApp.
- **Aguardando correção**: Usuário notificado para ajustar dados.
- **Aprovada**: Carteirinha emitida e token gerado.
- **Recusada**: Solicitação encerrada.
- **Renovação pendente**: Nova análise de renovação necessária.

---

## 🚀 Como Executar (Android)
1. **Ambiente**: Certifique-se de que o Flutter SDK e o Android SDK estão configurados.
2. **Dependências**:
   ```bash
   flutter pub get
   ```
3. **Execução**:
   - Inicie seu **Emulador Android** (via Android Studio ou VS Code).
   - Execute:
     ```bash
     flutter run
     ```
   *Nota: Não utilize `-d chrome` ou opções web.*

---

## 📂 Estrutura de Pastas
- `lib/core`: Temas, constantes de cores e configuração Firebase.
- `lib/models`: Modelos de dados e lógica de status/labels.
- `lib/services`: Serviços de Autenticação e Firestore.
- `lib/screens`: Interfaces divididas por módulos (User/Admin/Auth).
- `lib/widgets`: Componentes visuais reutilizáveis com foco em acessibilidade.

---
*Desenvolvido com foco em impacto social, privacidade e inclusão.*

---

## 🚀 Roadmap Concluído

### **v1.1.0 - Refactor & Cloud Integration** (Maio/2026)
*   **Migração de Backend**: Transição completa da infraestrutura de Supabase para **Firebase** (Auth e Firestore), garantindo maior escalabilidade e integração com serviços Google.
*   **Gerenciamento de Documentos via Google Drive**:
    *   Implementação de fluxo externo via Google Forms para coleta de documentos (privacidade-first).
    *   Integração de `driveLink` no dashboard administrativo para visualização direta dos anexos.
*   **Suporte a Múltiplas Carteirinhas**:
    *   Desenvolvimento de seletor de carteiras (Modal Picker) na tela inicial.
    *   Navegação dinâmica para responsáveis com mais de um dependente cadastrado.
*   **Painel Administrativo v2**:
    *   Interface de edição manual de metadados das carteirinhas.
    *   Botão de contato direto via WhatsApp (`wa.me`) integrado aos detalhes do pedido.
*   **Correções de Infraestrutura**:
    *   Padronização do sistema de cores (Tokens de Status).
    *   Otimização de performance em emuladores Android (Remoção de Impeller e ajustes de renderização).

### **v1.1.2 - Experiência de Visualização Premium** (Maio/2026)
*   **Otimização de Carteirinha**:
    *   Implementação de visualização **Horizontal (Landscape)** obrigatória para máxima legibilidade.
    *   Aumento significativo das dimensões do card para aproveitar a área útil do dispositivo.
    *   Refinamento estético com *glassmorphism* avançado e sombras dinâmicas.
*   **Correções de UI/UX**:
    *   Correção de bugs de layout (`EdgeInsets`) e tipagem de dados nas telas de usuário e admin.
    *   Melhoria no seletor de carteirinhas para múltiplos dependentes.
*   **Identidade Visual ConeCTEA**:
    *   Padronização completa seguindo o manual da marca: Azul Escuro (#0D1B4C), Azul Vivo (#1E63D8), Roxo (#8A44E8) e Teal (#4FD4C8).

### **v1.1.4 - Estabilidade & Visibilidade Total** (Maio/2026)
*   **Correção de Erros de Renderização**:
    - Eliminação completa dos erros de `RenderFlex overflow` (Portrait/Landscape) através de redimensionamento dinâmico via `FittedBox` e restrição de eixos.
    - Implementação de `textScaler: noScaling` para garantir que configurações de acessibilidade do sistema não quebrem a diagramação do documento.
*   **Visibilidade Absurda**:
    - Otimização do cálculo de área útil: a carteirinha agora ocupa até 92% da largura em modo paisagem, maximizando a legibilidade em qualquer dispositivo.
    - Margens dinâmicas que evitam cortes em telas com "notch" ou bordas arredondadas.
*   **Upgrade Visual Back-Card**:
    - Inclusão do logotipo oficial do **ConeCTEA** no verso (Segunda Imagem), reforçando a marca.
    - Adição de marca d'água institucional para maior segurança visual.
    - Novo sistema de campos (`Nº`, `CPF/RG`) com hierarquia visual clara e labels em caixa alta.
*   **Selo de Autenticidade TEA**:
    - Integração do Badge oficial do autismo no card frontal, facilitando a identificação imediata por autoridades e estabelecimentos.

### **v1.1.5 - Privacidade & Identidade Institucional** (Maio/2026)
*   **Privacidade-First (No Photo)**:
    - Remoção definitiva da exibição de fotos na carteirinha digital, substituindo-as por um **Selo Visual Institucional** com iniciais e ícone de verificação, alinhado com o manual da marca.
*   **Maximização de Área Útil**:
    - Ajuste nos cálculos de responsividade para ocupar 96% da largura em modo paisagem, garantindo que a carteirinha seja a maior possível na tela do usuário.
*   **Expansão de Marcas Relacionadas**:
    - Atualização do verso da carteirinha para incluir as entidades parceiras: **Família TEA Bauru** e o movimento `#TODOSPELOAUTISMO`, reforçando o caráter institucional e comunitário.
*   **Refinamento de Navegação**:
    - Melhoria no botão de alternância de orientação, permitindo transições mais fluidas entre o modo automático e o modo paisagem forçado.

### **v1.1.6 - Estabilização de Layout & Visibilidade Máxima** (Maio/2026)
*   **Correção Definitiva de Overflow**:
    - Reestruturação da tela `MyIDScreen` utilizando `LayoutBuilder` e `FittedBox` com sistema de coordenadas interno fixo (800x464), garantindo que a carteirinha nunca extrapole os limites físicos da tela, independente da densidade de pixels ou orientação.
    - Implementação de `textScaler: noScaling` reforçada para manter a integridade da diagramação institucional.
*   **Maximização de Área Útil (96%)**:
    - Ajuste fino para que a carteirinha ocupe **96% da largura disponível** em modo paisagem, tornando-a a maior possível para facilitar a leitura por terceiros.
*   **Identidade Visual "Seal-Only"**:
    - Evolução do design do selo institucional que substitui a foto, com tipografia em peso `w900` e iniciais dinâmicas, garantindo um visual premium e profissional.
*   **Aprimoramento do Verso (Back-Card)**:
    - Reorganização dos campos de "Informações Adicionais" com maior espaçamento e contraste.
    - Inclusão de marcas d'água decorativas e ícones institucionais (`psychology_rounded`) para reforçar a marca ConeCTEA.
*   **UX de Alta Performance**:
    - Adição de fundo decorativo em grade (*Grid Background*) para profundidade visual.
    - Melhoria no seletor de carteirinhas com maior área de toque e feedback visual de seleção.

## 🗺️ ROADMAP DE EVOLUÇÕES CONCLUÍDAS

### **v1.1.7 - Simulação Web & Estabilidade Estrutural** (Maio/2026)
*   **Simulação de Rotação em Ambiente Web**:
    - Implementação de "Rotação Virtual" para navegadores (Chrome/Edge), permitindo que o botão de virar a carteirinha funcione mesmo em simuladores que não suportam APIs de hardware de orientação.
*   **Fix de Sintaxe & Blocker**:
    - Resolução de erro crítico de escopo no método `didChangeDependencies` da `HomeScreen`.
*   **Otimização de Espaçamento Interno**:
    - Ajuste fino nas proporções do sistema de coordenadas `800x464` para evitar overflows.

### **v1.2.0 - Redesign Frontal & Foco no Membro** (Maio/2026)
*   **Reposicionamento de Branding**:
    - Marca "ConeCTEA" movida para o canto superior direito e reduzida em 20%, diminuindo sua proeminência e dando foco total aos dados do usuário.
*   **Layout de Dados em Linha Inteira**:
    - Os campos **Nº Registro** e **CPF/RG** agora ocupam a largura total da linha, eliminando a quebra de leitura e tornando a visualização mais institucional e profissional.
*   **Harmonia de Rodapé**:
    - Reposicionamento do símbolo do **Infinito** abaixo do badge de status.
    - Alinhamento do tag **Documento Digital Oficial** à direita, criando um equilíbrio visual simétrico com a logo no topo e o símbolo do infinito na base.
*   **Estabilização Estrutural**:
    - Implementação de `crossAxisAlignment: stretch` na coluna de dados para garantir que os campos sempre ocupem o espaço horizontal máximo disponível no grid de 800px.

### **v1.3.0 - Workflow de Status & Ações do Usuário** (Maio/2026)
*   **Novo Sistema de Status**:
    - Padronização do enum `RequestStatus` para cobrir todo o ciclo de vida: `pending`, `waitingDocument`, `approved`, `rejected`, `suspended`, `expired` e `renewalRequested`.
    - Implementação de metadados dinâmicos (Cores, Ícones, Labels e Descrições) centralizados no model `IDRequest`.
*   **Sistema de Ações Inteligentes**:
    - Botões dinâmicos com emojis que respondem ao status atual (ex: 📄 Enviar documentação, 📞 Falar com suporte).
    - Integração com `url_launcher` para abertura de links externos de documentação e WhatsApp.
    - Suporte nativo a renovação de carteirinhas vencidas com um clique.
*   **Privacidade & Transparência**:
    - Adição de notas de privacidade na interface: *"Nenhum documento será enviado ou salvo dentro do app"*, reforçando a segurança dos dados sensíveis.
    - Exibição clara de motivos de reprovação via modais informativos.
*   **Estabilidade Android**:
    - Configuração de `queries` no `AndroidManifest.xml` para garantir compatibilidade com intenções externas em versões recentes do Android.

---
*Este projeto segue uma filosofia de design premium e privacidade-first.*

