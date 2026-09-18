# Água Diária — app de consumo de água (SwiftUI)

App nativo em SwiftUI para registrar quanta água você bebe por dia, com meta,
histórico, gráfico e lembretes. Atualizado para compilar com **Xcode 26 ou
27**, com deployment target **iOS 17.0** e visual em **Liquid Glass** nos
sistemas **iOS 26 e iOS 27**.

## O que mudou nesta versão

- **`ObservableObject` → `@Observable`**: `WaterStore` agora usa a macro
  `@Observable` (iOS 17+) e é injetado com `.environment(store)` /
  `@Environment(WaterStore.self)`, no lugar de `@EnvironmentObject`.
- **Liquid Glass**: o anel de progresso, os cartões de resumo, os botões de
  atalho e os botões da folha de valor usam `.glassEffect`,
  `GlassEffectContainer` e os estilos `.glass` / `.glassProminent` a partir do
  iOS 26. Em iOS 17–25 o mesmo código cai automaticamente para um material
  translúcido (`.ultraThinMaterial`) parecido — **um único código-fonte
  funciona nas duas situações**, sem `#if` de compilação condicional.
- A barra de abas (`TabView`) e a barra de navegação já ficam em Liquid Glass
  sozinhas, de graça, assim que o app é compilado com o SDK do Xcode 26/27 —
  não foi necessário mexer nelas.
- **Lembretes assíncronos**: `NotificationManager` foi reescrito com
  `async`/`await` no lugar de completion handlers, para ficar em conformidade
  com a checagem estrita de concorrência do Swift 6.
- Ícone do app novo, pensado para o novo formato de ícones em camadas do
  iOS 26/27 (veja `AppIcon/`).

## Arquivos

| Arquivo | O que faz |
|---|---|
| `AguaDiariaApp.swift` | Ponto de entrada (`@main`) e as três abas |
| `Models.swift` | Unidade (ml/oz), registro, totais por dia, ajustes |
| `WaterStore.swift` | Estado do app (`@Observable`), cálculos e persistência |
| `NotificationManager.swift` | Lembretes locais repetitivos (async/await) |
| `Components.swift` | Tema, Liquid Glass, anel de progresso, botões, sheet |
| `TodayView.swift` | Aba Hoje |
| `HistoryView.swift` | Aba Histórico (Swift Charts) |
| `SettingsView.swift` | Aba Ajustes + calculadora de meta |
| `AppIcon/` | Ícone do app em Liquid Glass, pronto para importar |

## Como compilar

1. Use **Xcode 26** ou mais novo (idealmente **Xcode 27**, que já veio junto
   com o lançamento do iOS 27 em setembro de 2026). Versões mais antigas do
   Xcode não têm o SDK do iOS 26/27 e não vão aplicar o Liquid Glass.
2. Abra o Xcode: **File > New > Project… > iOS > App**.
3. Preencha:
   - Product Name: `AguaDiaria`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (não marque Core Data nem SwiftData)
4. Depois de criado, selecione o alvo do projeto > aba **General** >
   **Minimum Deployments** > **iOS 17.0**.
5. Apague os dois arquivos que o Xcode gerou (`AguaDiariaApp.swift` e
   `ContentView.swift`) escolhendo *Move to Trash*.
6. Arraste os 8 arquivos `.swift` desta pasta para dentro do projeto no Xcode,
   marcando **Copy items if needed** e o target `AguaDiaria`.
7. Importe o ícone (veja a seção **Ícone do app** abaixo).
8. Aba **Signing & Capabilities**: escolha seu **Team**. Uma conta Apple
   gratuita funciona — o app instalado expira em 7 dias e precisa ser
   reinstalado depois disso.
9. Conecte o iPhone, selecione-o na barra superior e aperte **⌘R**.
10. Na primeira execução, no iPhone: **Ajustes > Geral > VPN e Gerenciamento
    de Dispositivo** > confie no seu certificado de desenvolvedor.

### Swift Language Version

O projeto deve funcionar tanto em **Swift 5** quanto em **Swift 6** (modo de
concorrência estrita), já que o código foi revisado para isso (classe
`@MainActor`, `NotificationManager` assíncrono, modelos `Sendable`). Se o
Xcode marcar algum aviso de concorrência em uma versão de SDK muito nova,
confira **Build Settings > Swift Compiler - Language > Swift Language
Version**.

## Ícone do app (Liquid Glass)

A pasta `AppIcon/` traz duas opções — use a que preferir:

1. **Simples (funciona em qualquer Xcode)**: `AppIcon/AppIcon.appiconset`
   já é um conjunto pronto do Xcode, com um único ícone de 1024×1024 em
   estilo "vidro líquido" (gota de água com brilho e transparência). Basta
   arrastar a pasta `AppIcon.appiconset` para dentro de `Assets.xcassets` no
   Xcode (substituindo o `AppIcon` padrão).
2. **Camadas para o Icon Composer (visual "de verdade" no iOS 26/27)**: a
   partir do Xcode 26, ícones podem ser montados no app **Icon Composer**
   (Xcode > Open Developer Tool > Icon Composer, ou standalone) com camadas
   separadas que o sistema ilumina e faz de vidro em tempo real, reagindo ao
   giro do aparelho e ao modo claro/escuro/tintado. Os arquivos
   `AppIcon/layers/background.png`, `AppIcon/layers/drop.png` e
   `AppIcon/layers/highlight.png` (todos 1024×1024) já vêm separados para
   isso: abra o Icon Composer, crie um ícone novo, arraste os três PNGs como
   três camadas nessa ordem (fundo, gota, brilho) e exporte um arquivo
   `.icon` para o projeto. Esse caminho dá o efeito de Liquid Glass completo
   (especular, translúcido, reage à luz); o ícone simples da opção 1 é uma
   versão já "achatada" do mesmo desenho, para quem não quiser usar o Icon
   Composer.

## Compatibilidade

- **Deployment target: iOS 17.0.** O app roda normalmente do iOS 17 ao
  iOS 27, mas os efeitos de Liquid Glass (`.glassEffect`, `GlassEffectContainer`,
  `.buttonStyle(.glass/.glassProminent)`) só aparecem a partir do **iOS 26**;
  em versões antes disso o mesmo código usa um material translúcido comum.
- Recursos usados a partir do iOS 17: macro `@Observable`, `@Bindable`,
  `onChange(of:) { }` sem parâmetro.
- Nenhuma chave nova é necessária no `Info.plist`. A partir do Xcode 27, a
  flag de compatibilidade `UIDesignRequiresCompatibility` (que no Xcode 26
  permitia manter o visual antigo por uma versão) deixou de funcionar — todo
  app recompilado adota o Liquid Glass automaticamente nos controles padrão.

## Como os dados são guardados

- Registros: `Documents/aguadiaria-registros.json`, salvo a cada mudança e
  quando o app vai para segundo plano.
- Ajustes: `UserDefaults`, chave `aguadiaria.settings.v1`.
- Nada sai do aparelho e não há nenhuma chamada de rede.

O "dia" é calculado por `Calendar.startOfDay`, então a virada acontece sozinha
à meia-noite — não existe reset manual para dar errado.

## Lembretes

Os lembretes são `UNCalendarNotificationTrigger` com `repeats: true`, um por
horário entre o início e o fim configurados. Não é preciso adicionar chave no
Info.plist nem ativar capability: a permissão é pedida (de forma assíncrona)
quando você liga o toggle em Ajustes.

## Ideias para a próxima versão

- **Widget** na tela de início com o anel de progresso (WidgetKit), já com
  Liquid Glass no próprio widget.
- **HealthKit**: gravar em `HKQuantityTypeIdentifier.dietaryWater` para o app
  Saúde receber os registros (precisa da capability e das chaves
  `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`).
- **iCloud** via CloudKit para sincronizar entre aparelhos.
- **Live Activity** durante o dia, também em Liquid Glass.
- Diferenciar bebidas (café, chá, suco) com fator de hidratação por tipo.
