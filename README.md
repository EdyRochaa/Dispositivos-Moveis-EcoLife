# 🌱 EcoLife — Aplicativo de Sustentabilidade

Aplicativo mobile desenvolvido em Flutter com integração ao Firebase, voltado para o registro de hábitos sustentáveis, acompanhamento de progresso e engajamento com a comunidade EcoLife.

---

## 🚀 Tecnologias utilizadas

- Flutter 3.44.0 / Dart 3.12.0
- Firebase Authentication (E-mail/Senha + Google Sign-In)
- Cloud Firestore (CRUD em tempo real)
- Google Sign-In
- PDF / Printing
- Geolocator / Flutter Map

---

## 🔐 Segurança e Regras de Negócio

- Acesso restrito ao domínio institucional `@souunit.com.br`
- Logout imediato caso o e-mail não pertença ao domínio
- Todos os registros no Firestore contêm os campos `criado_por` e `usuario_logado` com o e-mail autenticado pelo Firebase

---

## ☁️ Firebase — CRUD implementado

| Operação | Método | Descrição |
|----------|--------|-----------|
| **Create** | `.set()` | Salva dados do usuário no cadastro |
| **Read** | `.get()` | Carrega dados no login, perfil e exportação |
| **Update** | `.update()` | Atualiza `lastLogin` e `usuario_logado` a cada login |
| **Delete** | `.delete()` | Remove documento ao excluir conta |

---

## 👥 Divisão de Tarefas

| Nome do Aluno | Telas sob sua responsabilidade | Status | Link do Vídeo de Defesa |
|---|---|---|---|
| Edy Rocha | Splash Screen, Navegação Global, Firebase Integration | ✅ | — |
| Maria Helloisa | Login | ✅ | — |
| Boaz Henrique | Progresso / Impacto | ✅ | — |
| Bianca Repolho | Home / Dashboard, Desafios, Perfil, Design System | ✅ | — |
| João Felipe | Desafios (Lista de Hábitos), CRUD | ✅ | — |

---

## 🔧 Edy Rocha — Tech Lead / Full-Stack

**Telas: Splash Screen + Integração Firebase**

- [x] Animação inicial da Splash Screen (logo animado com fade + slide)
- [x] Estrutura de navegação global (`Bottom Navigation Bar`: Home · Impacto · Desafios · Comunidade · Perfil)
- [x] Configuração inicial do projeto (estrutura de pastas, dependências, roteamento)
- [x] Integração completa com Firebase Authentication (E-mail/Senha + Google Sign-In)
- [x] Regra de domínio `@souunit.com.br` com logout imediato para e-mails inválidos
- [x] Cloud Firestore — CRUD completo (`criado_por`, `usuario_logado`, `lastLogin`)
- [x] Exportação de dados (PDF, JSON, CSV) conforme LGPD

---

## 🎨 Maria Helloisa — UX Designer / Frontend

**Tela: Login**

- [x] Autenticação via e-mail e senha
- [x] Login com Google (Google Sign-In)
- [x] Validação de domínio `@souunit.com.br`
- [x] Botão Entrar em destaque e link para tela de Cadastro

---

## ⚙️ Boaz Henrique — Backend / QA

**Tela: Progresso / Impacto**

- [x] Gráfico de barras do Progresso Semanal
- [x] Métricas: Carbono Reduzido (kg), Water Saved, Carbon Saved
- [x] Emblemas conquistados pelo usuário
- [x] Lógica de persistência dos dados de progresso

---

## 🎨 Bianca Repolho — UX Designer / Frontend

> Responsável pelo design de interface, componentes de UI e estilização visual.

**Telas / Responsabilidades:**

- [x] Tela **Home / Dashboard** — Pontuação Verde, dicas diárias, atividades recentes
- [x] Tela de **Desafios** — lista semanal de hábitos com checkboxes (RF06 — Registro diário)
- [x] Tela de **Perfil** — foto, dados pessoais, configurações (notificações, modo escuro, localização)
- [x] Sistema de design: paleta de cores, tipografia, ícones e componentes visuais globais

---

## ⚙️ João Felipe — Backend / QA

**Tela: Desafios (Lista de Hábitos)**

- [x] Lista semanal de hábitos sustentáveis com checkboxes
- [x] Categorias: transporte público, economia de energia, reciclagem, dieta
- [x] Marcar hábito como concluído no dia (RF06 — Registro diário)
- [x] CRUD completo: Cadastro, Edição e Exclusão de hábito com confirmação

---

## ▶️ Como executar

```bash
# Instalar dependências
flutter pub get

# Rodar no Chrome
flutter run -d chrome
```

---

*Desenvolvido para a disciplina de Dispositivos Móveis — UNIT*
