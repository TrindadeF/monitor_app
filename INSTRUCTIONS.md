# Instruções de Execução e Teste

## Requisitos

- Flutter 3.x ou superior
- Android SDK 28+ (Android 8.0 Oreo ou superior)
- Dispositivo físico Android (o app usa recursos que não funcionam no emulador)

## Como executar o projeto

1. **Clone o repositório**:
   ```bash
   git clone https://seu-repositorio/monitor_corridas.git
   cd monitor_corridas/monitor_app
   ```

2. **Instale as dependências**:
   ```bash
   flutter pub get
   ```

3. **Execute o app**:
   ```bash
   flutter run
   ```

## Guia de Teste

### Testando com imagens simuladas

1. Abra o aplicativo e toque no ícone de "bug" no canto superior direito
2. Na tela de teste, você verá uma imagem simulada de um card do Uber
3. Toque no botão "Processar OCR" para extrair os dados da imagem
4. Você pode alternar entre cards simulados do Uber e 99 tocando no ícone de alternância na barra superior
5. Verifique a precisão da extração e cálculos

### Testando em produção

1. Instale o app no seu dispositivo Android
2. Conceda permissão para captura de tela quando solicitado
3. Toque no botão "INICIAR MONITORAMENTO"
4. Abra o aplicativo Uber ou 99 (driver)
5. Quando aparecer uma solicitação de corrida, os valores serão automaticamente extraídos e os cálculos serão exibidos na interface do app Monitor de Corridas
6. Use os switches para ativar/desativar os diferentes cálculos conforme sua necessidade

## Solução de Problemas

### Permissão de captura de tela negada

Se você negar a permissão de captura de tela:
1. Vá para Configurações > Aplicativos > Monitor de Corridas > Permissões
2. Ative a permissão "Captura de tela"
3. Reinicie o aplicativo

### OCR não detecta valores

Se o OCR não estiver detectando corretamente os valores:
1. Verifique se o brilho da tela está adequado
2. Certifique-se de que não há sobreposições na tela do app de corrida
3. O cartão de solicitação de corrida deve estar completamente visível

### Serviço em segundo plano parou

Em alguns dispositivos, o serviço em segundo plano pode ser interrompido pelo sistema para economizar bateria:
1. Vá para Configurações > Bateria > Otimização de bateria
2. Encontre "Monitor de Corridas" e selecione "Não otimizar"
3. Reinicie o aplicativo

## Modificando o Projeto

### Estrutura do código

- `lib/models/` - Classes de dados e configurações
- `lib/services/` - Lógica de negócio e interação com APIs
- `lib/screens/` - Interfaces de usuário
- `lib/widgets/` - Componentes reutilizáveis da UI
- `lib/utils/` - Utilitários e helpers

### Para adicionar suporte a outros apps de corrida

1. Analise o layout do card de solicitação do novo app
2. Atualize as expressões regulares em `ocr_service.dart`
3. Crie um gerador de imagens de teste para o novo app em `mock_image_generator.dart`
4. Atualize a UI para incluir o novo app na lista de aplicativos suportados
