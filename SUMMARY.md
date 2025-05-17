# Resumo da Implementação do Monitor de Corridas

## Arquitetura e Componentes

1. **Modelos**
   - `RideData`: Armazena e calcula métricas para dados de corridas (preço, distância, tempo)
   - `AppSettings`: Gerencia as configurações do aplicativo com SharedPreferences

2. **Serviços**
   - `OcrService`: Utiliza Google ML Kit para extrair texto das imagens de corridas
   - `ScreenCaptureService`: Implementa a captura de tela em segundo plano
   - `RideViewModel`: Integra os dados e configurações para a UI

3. **Telas**
   - `HomeScreen`: Interface principal mostrando métricas e controles
   - `TestScreen`: Ambiente para testar OCR com imagens simuladas

4. **Widgets**
   - `PriceIndicator`: Exibe métricas calculadas com switch para ativar/desativar
   - `MonitorControl`: Controles para iniciar/parar monitoramento

5. **Utilitários**
   - `MockImageGenerator`: Gera imagens de teste simulando cards de Uber e 99

## Funcionalidades Implementadas

1. **Captura de tela baseada em eventos**
   - Implementado através do plugin Flutter Background Service
   - Usa NotificationListenerService para detectar ofertas de corrida nos apps
   - Usa MediaProjection API do Android para captura de tela apenas quando necessário
   - Sistema de overlay para exibir métricas sobre os apps originais

2. **OCR para extração de dados**
   - Usa Google ML Kit para reconhecimento de texto
   - Extrai valores com expressões regulares (RegExp)
   - Manipula formatação de números brasileiros (vírgula como separador decimal)

3. **Cálculos em tempo real**
   - Valor por km
   - Valor por minuto
   - Valor por trecho total (cálculo combinado)

4. **Persistência**
   - Salva configurações de usuário com SharedPreferences
   - Mantém estado dos switches de exibição entre sessões

5. **Modo de teste**
   - Gera imagens simuladas para testes sem depender de arquivos externos
   - Permite alternar entre simulações de Uber e 99

## Permissões e Configurações Nativas

1. **Permissões Android**
   - `BIND_NOTIFICATION_LISTENER_SERVICE`: Para detectar notificações de ofertas de corrida
   - `SYSTEM_ALERT_WINDOW`: Para exibir overlay sobre os aplicativos
   - `FOREGROUND_SERVICE_MEDIA_PROJECTION`: Para captura de tela em segundo plano
   - `POST_NOTIFICATIONS`: Para notificações do serviço em segundo plano
   - `STORAGE`: Para salvar dados temporários 

2. **Componentes Nativos**
   - `NotificationListenerService`: Para detectar notificações dos apps Uber/99
   - `OverlayService`: Para exibir as métricas calculadas sobre outros apps
   - `MediaProjection`: Para captura de tela quando necessário

3. **Melhorias de Performance**
   - Captura de tela apenas quando detectada oferta de corrida (substituindo timer periódico)
   - Uso de EventChannel para comunicação entre Java/Kotlin e Flutter
   - Interface de usuário para gerenciamento de permissões

1. **Permissões necessárias**:
   - FOREGROUND_SERVICE
   - FOREGROUND_SERVICE_MEDIA_PROJECTION
   - READ/WRITE_EXTERNAL_STORAGE
   - INTERNET

2. **Implementação nativa Android**:
   - Integração com MediaProjection para captura de tela
   - Canal de comunicação (Method Channel) para interagir com a API nativa

## Melhorias Potenciais

1. **Detecção mais precisa**:
   - Treinamento específico para formatos de cards de corrida
   - Reconhecimento por região específica da tela

2. **Desempenho**:
   - Otimizar frequência de captura de tela
   - Melhorar processamento de imagem para reduzir consumo de bateria

3. **Funcionalidades adicionais**:
   - Histórico de corridas
   - Estatísticas por período (dia, semana, mês)
   - Notificações para corridas com alto potencial de ganho
