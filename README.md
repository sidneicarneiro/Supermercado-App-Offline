# Lista de Compras

Este é um aplicativo Flutter para gerenciamento de listas de compras. Com ele, você pode criar listas, adicionar itens, registrar preços e quantidades, além de acompanhar o total gasto em cada lista.

## Funcionalidades

- Autenticação de usuário
- Criação e edição de listas de compras
- Adição, edição e exclusão de itens nas listas
- Cálculo automático do valor total da lista
- Validação de token de autenticação
- Interface simples e intuitiva

## Pré-requisitos

- [Flutter](https://flutter.dev/docs/get-started/install) (versão 3.0 ou superior)
- [Dart](https://dart.dev/get-dart)
- Android Studio ou VS Code (opcional, mas recomendado)

## Como compilar e rodar

1. **Clone o repositório:**
   ```sh
   git clone https://github.com/sidneicarneiro/Supermercado-App.git
   cd seu-repositorio 
   ```
2. **Instale as dependências:**
   ```sh
   flutter pub get
   ```
3. **Compile o aplicativo:**
   ```sh
    flutter build apk
    ```
4. **Para rodar no android:**
   - Conecte um dispositivo Android ou inicie um emulador.
   - Execute `flutter run` para instalar e iniciar o aplicativo.
   - Certifique-se de que o dispositivo esteja configurado para permitir a instalação de aplicativos de fontes desconhecidas.
5. **Para rodar no iOS:**
   - Abra o projeto no Xcode: `open ios/Runner.xcworkspace`.
   - Conecte um dispositivo iOS ou inicie um simulador.
   - No Xcode, selecione o dispositivo e clique em "Run" para compilar e instalar o aplicativo.
   - Certifique-se de que o dispositivo esteja configurado para permitir a instalação de aplicativos de fontes desconhecidas.
   - Para rodar no iOS, você precisará de uma conta de desenvolvedor Apple e configurar o provisioning profile corretamente.
   - Se estiver usando um simulador, você pode rodar diretamente pelo Xcode ou pelo terminal com `flutter run`.
6. **Acesse a aplicação:**
   - Após a instalação, abra o aplicativo no dispositivo.
   - Use as credenciais de um usuário existente para fazer login ou crie um novo usuário se necessário.