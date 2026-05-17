# Matriz de Dispositivos — ConeCTEA

**App:** 0.5.0-dev  
**Documentação:** 4.2.0  
**Status:** Desenvolvimento
**Atualizado em:** 17/05/2026

---

## Objetivo

Mapear a matriz de dispositivos de referência e o protocolo de simulações utilizadas na bancada oficial de QA do ConeCTEA para apoiar a responsividade do aplicativo nos cenários testados.

---

## 1. Bancada de Validação em Emuladores (Frente 26A)

Estes quatro perfis cobrem os comportamentos mais extremos encontrados em produção no mercado brasileiro:

| Dispositivo de Referência | Resolução Lógica | Tipo de Tela | Entalhe (Cutout) Simulador | Foco de Validação da Frente 26A |
| :--- | :--- | :--- | :--- | :--- |
| **Samsung A05/A06** | 360 x 800 dp | Estreita / Standard | Notch em Gota (Teardrop) | Validação de compactação extrema e navegação de 3 botões tradicionais. |
| **Samsung ZFlip** | 412 x 940 dp | Ultra Tall (Esticada) | Furo Central (Punch Hole) | Validação de restrições verticais (garantia de que cards não esticam e não geram vãos). |
| **Motorola Edge Curved** | 384 x 840 dp | Curva Lateral | Waterfall Cutout | Validação de SafeAreas laterais e proteção contra distorção de borda. |
| **Motorola Razr Open** | 412 x 870 dp | Larga / Alta Densidade | Furo Duplo (Double Cutout) | Validação de alinhamento de carrossel horizontal e cenário recomendado de escala de fonte. |

---

## 2. Matriz Estendida de QA (Validações Adicionais)

Para testes secundários de regressão e validação de releases:
- **Samsung A15/A16 (360dp):** Dispositivo de massa (padrão de mercado).
- **Samsung A35/A36 (384dp):** Perfil intermediário com cantos arredondados acentuados.
- **Samsung A55/A56 (400dp):** Perfil de referência de bancada.
- **Samsung S24/S25 (360dp):** Furo de câmera ultra-discreto no topo central.
- **Samsung S24 Ultra (480dp):** Perfil largo para testar estiramento horizontal de layouts Dark Glass.
- **Motorola Edge 40 Neo (400dp):** Cantos de tela super arredondados (Corner Cutout).
- **Xiaomi Redmi/POCO (438dp):** Alta resolução horizontal com zoom padrão diferenciado.

---

## 3. Protocolo de Simulação de Hardware

Todas as validações da Frente 26A passam pelas seguintes simulações recomendadas via opções de desenvolvedor do Android AVD:

### 3.1 Modos de Navegação de Sistema
- **Navegação por Gestos:** Para verificar que o indicador de gestos do Android (barra horizontal flutuante) não sobrepõe textos ou botões ativos da `PremiumBottomNavBar`.
- **Navegação por 3 Botões:** Para verificar que a altura útil reduzida não empurra o layout para cima de forma a quebrar contêineres horizontais.

### 3.2 Escala de Fonte e Zoom do Sistema
- **Zoom em 1.2x (Médio):** Escala de legibilidade sugerida para testes.
- **Zoom em 1.5x (Extremo):** Cenário de teste recomendado para apoiar o funcionamento das proteções textuais e de `BoxConstraints(minHeight: 64)` do `HomeMembersSection`.
