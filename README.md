# Monitor de Corridas

Aplicativo para monitorar automaticamente corridas do Uber e 99, extraindo preços, distâncias e tempos de viagens, e calculando métricas úteis para motoristas.

## Funcionalidades

- **Monitoramento em segundo plano**: Captura de tela automática para detectar cards de corrida
- **OCR inteligente**: Extrai preço, distância e tempo de viagem
- **Cálculos em tempo real**:
  - Valor por km
  - Valor por minuto 
  - Valor por trecho total
- **Interface minimalista**: Exibe apenas os valores calculados com opção de habilitar/desabilitar cada métrica

## Requisitos Técnicos

- Flutter 3.x+
- Android 8.0 ou superior
- Permissão de captura de tela

## Como usar

1. **Instalar o aplicativo**:
   ```
   flutter pub get
   flutter run
   ```

2. **Configurar permissões**:
   - Na primeira execução, o app solicitará permissão para capturar a tela
   - Esta permissão é essencial para o funcionamento do aplicativo

3. **Iniciar monitoramento**:
   - Abra o app Monitor de Corridas
   - Toque no botão "INICIAR MONITORAMENTO"
   - Deixe o app rodando em segundo plano enquanto usa o Uber ou 99

4. **Visualizar métricas**:
   - Quando um card de corrida aparecer, os valores serão calculados automaticamente
   - Use os switches para mostrar/esconder cada métrica conforme sua preferência

## Estrutura do Código

- **models/**: Classes de dados e configurações
- **services/**: Serviços de OCR, captura de tela e viewmodel
- **screens/**: Telas do aplicativo
- **widgets/**: Componentes reutilizáveis da UI

## Testando o aplicativo

### Teste com imagens simuladas

O aplicativo inclui imagens de teste em `assets/test_images/`. Para testar o reconhecimento OCR com estas imagens:

1. Execute o app em modo de desenvolvimento
2. Na tela principal, use a opção de menu para acessar o modo de teste
3. Selecione uma das imagens de teste para ver o resultado da extração

### Configuração de permissões no AndroidManifest

O aplicativo requer as seguintes permissões no AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
```

## Limitações

- Funciona apenas no Android
- O OCR pode falhar em algumas situações (texto pequeno, fontes diferentes, etc.)
- O app funciona melhor com o telefone na orientação vertical

## Sugestões de Melhoria

- Adicionar histórico de corridas
- Melhorar precisão do OCR com treinamento específico
- Adicionar estatísticas de ganhos por hora/dia/semana
- Suporte para mais aplicativos de corrida

---

Desenvolvido como prova de conceito. Este aplicativo não é afiliado ao Uber ou 99.
