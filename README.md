# Água Diária — app de consumo de água (SwiftUI)

App nativo em SwiftUI para registrar quanta água você bebe por dia, com meta,
histórico, gráfico e lembretes. Escrito para compilar no Xcode do macOS Sequoia
e rodar em iPhone com **iOS 16 e iOS 17**.

## Arquivos

| Arquivo | O que faz |
|---|---|
| `AguaDiariaApp.swift` | Ponto de entrada (`@main`) e as três abas |
| `Models.swift` | Unidade (ml/oz), registro, totais por dia, ajustes |
| `WaterStore.swift` | Estado do app, cálculos e persistência |
| `NotificationManager.swift` | Lembretes locais repetitivos |
| `Components.swift` | Tema, anel de progresso, botões, sheet de valor |
| `TodayView.swift` | Aba Hoje |
| `HistoryView.swift` | Aba Histórico (Swift Charts) |
| `SettingsView.swift` | Aba Ajustes + calculadora de meta |

## Como compilar

1. Abra o Xcode: **File > New > Project… > iOS > App**.
2. Preencha:
   - Product Name: `AguaDiaria`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None** (não marque Core Data nem SwiftData)
3. Depois de criado, selecione o alvo do projeto > aba **General** >
   **Minimum Deployments** > **iOS 16.0**.
4. Apague os dois arquivos que o Xcode gerou (`AguaDiariaApp.swift` e
   `ContentView.swift`) escolhendo *Move to Trash*.
5. Arraste os 8 arquivos `.swift` desta pasta para dentro do projeto no Xcode,
   marcando **Copy items if needed** e o target `AguaDiaria`.
6. Aba **Signing & Capabilities**: escolha seu **Team**. Uma conta Apple
   gratuita funciona — o app instalado expira em 7 dias e precisa ser
   reinstalado depois disso.
7. Conecte o iPhone, selecione-o na barra superior e aperte **⌘R**.
8. Na primeira execução, no iPhone: **Ajustes > Geral > VPN e Gerenciamento de
   Dispositivo** > confie no seu certificado de desenvolvedor.

### Se o seu Xcode usar Swift 6 por padrão

Projetos novos em versões recentes do Xcode podem vir com o modo de linguagem
Swift 6, cuja concorrência estrita gera erros em código escrito no estilo
clássico de `ObservableObject`. Para evitar isso:

**Build Settings > Swift Compiler - Language > Swift Language Version → Swift 5**

O código todo compila sem avisos relevantes nesse modo.

## Compatibilidade com iOS 16

O código evita de propósito tudo que só existe do iOS 17 para cima:

- `ObservableObject` + `@Published` no lugar da macro `@Observable`
- JSON em arquivo no lugar de SwiftData
- `onChange(of:) { valor in }` na forma de um parâmetro
- nada de `ContentUnavailableView`, `Observable`, `SwiftData` ou `@Bindable`

E usa recursos disponíveis a partir do iOS 16: `NavigationStack`, Swift Charts
(`BarMark`, `RuleMark`), `presentationDetents` e `Grid`/`LazyVGrid`.

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
Info.plist nem ativar capability: a permissão é pedida quando você liga o
toggle em Ajustes.

## Ideias para a próxima versão

- **Widget** na tela de início com o anel de progresso (WidgetKit; um widget
  interativo com botão de +1 copo exige iOS 17, então ficaria como recurso
  condicional).
- **HealthKit**: gravar em `HKQuantityTypeIdentifier.dietaryWater` para o app
  Saúde receber os registros (precisa da capability e das chaves
  `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`).
- **iCloud** via CloudKit para sincronizar entre aparelhos.
- **Live Activity** durante o dia (iOS 16.1+).
- Diferenciar bebidas (café, chá, suco) com fator de hidratação por tipo.
